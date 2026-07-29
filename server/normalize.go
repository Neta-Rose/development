package main

import (
	"sort"
	"strings"
	"unicode"
)

// Bounds the client also applies. Duplicated here on purpose: this copy is the
// one a caller cannot edit, and the client's copy is the one that still holds
// when a reply arrives from a stubbed or future backend.
const (
	minGrams = 1.0
	maxGrams = 2000.0
	maxIDLen = 40
)

// normalizeDetections is the deduplication safety net.
//
// The model is instructed to emit one entry per physical item and to reuse ids
// across shots, and a well-behaved model needs nothing here. But a model that
// slips — emitting the same chicken thigh twice in one reply, or minting
// `chicken_2` for an item the request already named `chicken_1` — would put two
// rows on the plate and log the food twice, which is the exact failure this
// feature exists to prevent. So the invariant is enforced rather than trusted:
//
//  1. ids are slugified, and unusable entries are dropped;
//  2. numbers are clamped into loggable ranges;
//  3. shot numbers are deduplicated, bounded and sorted;
//  4. an id that is new but names a food already on the plate adopts the plate's
//     id, unless that id appears in the reply on its own account;
//  5. entries sharing an id after (4) collapse into one, unioning their shots.
//
// Order matters: (4) can create duplicates, so (5) runs after it. First-seen
// order is preserved throughout, so the plate does not reshuffle between shots.
func normalizeDetections(in []Detection, shotCount int, plate []PlateItem) []Detection {
	if shotCount < 1 {
		shotCount = 1
	}

	cleaned := make([]Detection, 0, len(in))
	for _, d := range in {
		id := slugifyID(d.InstanceID)
		name := strings.TrimSpace(d.Name)
		// No id means nothing can be merged against it, and no name means
		// nothing can be rendered or searched for. Either way the entry is
		// unusable rather than merely imperfect.
		if id == "" || name == "" {
			continue
		}
		cleaned = append(cleaned, Detection{
			InstanceID: id,
			Name:       name,
			SearchTerm: fallbackTerm(d.SearchTerm, name),
			Grams:      clampGrams(d.Grams),
			Confidence: clamp(d.Confidence, 0, 1),
			Shots:      normalizeShots(d.Shots, shotCount),
			Emoji:      firstEmoji(d.Emoji),
			// Negative energy or macros are always a model error, never real
			// data. (The opposite is true of the USDA catalog, where a negative
			// carbohydrate-by-difference is genuine — that path must not clamp.)
			Kcal100g:    atLeastZero(d.Kcal100g),
			Protein100g: atLeastZero(d.Protein100g),
			Carb100g:    atLeastZero(d.Carb100g),
			Fat100g:     atLeastZero(d.Fat100g),
		})
	}

	aliasToPlateIDs(cleaned, plate)
	return collapseByID(cleaned)
}

// aliasToPlateIDs rewrites ids in place: a detection whose id is unknown but
// whose name matches a staged item adopts the staged id, so the client merges it
// into the existing row instead of appending a second one.
//
// The guard is deliberately narrow. It only fires when the staged id is absent
// from the reply, because if the model returned both `chicken_1` and a separate
// `chicken_2` it is claiming two chicken thighs, and rule 4 of the prompt says
// that is legitimate — two physical items of one food are two entries.
func aliasToPlateIDs(items []Detection, plate []PlateItem) {
	if len(plate) == 0 || len(items) == 0 {
		return
	}

	returned := make(map[string]bool, len(items))
	for _, d := range items {
		returned[d.InstanceID] = true
	}

	stagedByName := make(map[string]string, len(plate))
	stagedIDs := make(map[string]bool, len(plate))
	for _, p := range plate {
		id := slugifyID(p.InstanceID)
		if id == "" {
			continue
		}
		stagedIDs[id] = true
		key := nameKey(p.Name)
		// First staged item wins a contested name, so aliasing is deterministic.
		if key != "" && stagedByName[key] == "" {
			stagedByName[key] = id
		}
	}

	for i := range items {
		if stagedIDs[items[i].InstanceID] {
			continue // already a staged id; nothing to repair
		}
		staged := stagedByName[nameKey(items[i].Name)]
		if staged == "" || returned[staged] {
			continue
		}
		items[i].InstanceID = staged
		returned[staged] = true
	}
}

// collapseByID folds entries sharing an id into one. Shots union; the scalar
// fields come from the highest-confidence entry, which is the one most likely to
// have read the food correctly.
func collapseByID(items []Detection) []Detection {
	order := make([]string, 0, len(items))
	byID := make(map[string]Detection, len(items))

	for _, d := range items {
		prev, seen := byID[d.InstanceID]
		if !seen {
			order = append(order, d.InstanceID)
			byID[d.InstanceID] = d
			continue
		}
		shots := mergeShots(prev.Shots, d.Shots)
		winner := prev
		if d.Confidence > prev.Confidence {
			winner = d
		}
		winner.Shots = shots
		byID[d.InstanceID] = winner
	}

	out := make([]Detection, 0, len(order))
	for _, id := range order {
		out = append(out, byID[id])
	}
	return out
}

// slugifyID reduces an id to lowercase ASCII letters, digits and single
// underscores, so two ids that differ only in punctuation or case are the same
// id and merge instead of forking the plate.
func slugifyID(raw string) string {
	var b strings.Builder
	lastUnderscore := true // suppresses a leading underscore
	for _, r := range strings.ToLower(strings.TrimSpace(raw)) {
		switch {
		case r >= 'a' && r <= 'z', r >= '0' && r <= '9':
			b.WriteRune(r)
			lastUnderscore = false
		default:
			if !lastUnderscore {
				b.WriteByte('_')
				lastUnderscore = true
			}
		}
		if b.Len() >= maxIDLen {
			break
		}
	}
	return strings.Trim(b.String(), "_")
}

// nameKey is an order-independent, plural-insensitive form of a food name, used
// only to spot that two names mean the same food. `Cherry tomatoes` and
// `tomato, cherry` both reduce to `cherri tomato`-ish token sets.
func nameKey(raw string) string {
	tokens := strings.FieldsFunc(strings.ToLower(raw), func(r rune) bool {
		return !unicode.IsLetter(r) && !unicode.IsDigit(r)
	})
	out := make([]string, 0, len(tokens))
	for _, t := range tokens {
		out = append(out, singular(t))
	}
	if len(out) == 0 {
		return ""
	}
	sort.Strings(out)
	return strings.Join(out, " ")
}

// singular folds a trailing plural, but only on tokens long enough that the
// suffix is unlikely to be part of the word — `oats` must not become `oat`'s
// neighbour by way of `as` becoming `a`.
func singular(t string) string {
	switch {
	case len(t) > 4 && strings.HasSuffix(t, "es"):
		return t[:len(t)-2]
	case len(t) > 3 && strings.HasSuffix(t, "s") && !strings.HasSuffix(t, "ss"):
		return t[:len(t)-1]
	default:
		return t
	}
}

// fallbackTerm keeps the catalog lookup from being handed an empty string: the
// display name is a worse search term than a generic one, but far better than
// nothing.
func fallbackTerm(term, name string) string {
	if t := strings.TrimSpace(term); t != "" {
		return t
	}
	return name
}

// clampGrams returns the amount when it is loggable, and 0 to mean "no usable
// estimate". 0 is a signal, not a weight: the client resolves it against the
// matched food's serving weight, which this service cannot see.
func clampGrams(g float64) float64 {
	if g < minGrams || g > maxGrams || g != g { // g != g rejects NaN
		return 0
	}
	return float64(int(g + 0.5))
}

func normalizeShots(shots []int, shotCount int) []int {
	seen := make(map[int]bool, len(shots))
	out := make([]int, 0, len(shots))
	for _, s := range shots {
		if s < 1 || s > shotCount || seen[s] {
			continue
		}
		seen[s] = true
		out = append(out, s)
	}
	if len(out) == 0 {
		// A detection with no usable shot list still came out of this batch, so
		// it belongs to the newest shot — which is also what makes it render
		// with the `new` badge rather than silently as an old row.
		return []int{shotCount}
	}
	sort.Ints(out)
	return out
}

func mergeShots(a, b []int) []int {
	seen := make(map[int]bool, len(a)+len(b))
	out := make([]int, 0, len(a)+len(b))
	for _, s := range append(append([]int{}, a...), b...) {
		if seen[s] {
			continue
		}
		seen[s] = true
		out = append(out, s)
	}
	sort.Ints(out)
	return out
}

// firstEmoji keeps one grapheme-ish rune sequence and drops any trailing prose,
// since some models answer "🍗 chicken" for a field asking for one emoji. An
// empty result is fine; the client renders 🍽️ for it.
func firstEmoji(raw string) string {
	raw = strings.TrimSpace(raw)
	if raw == "" {
		return ""
	}
	var b strings.Builder
	for _, r := range raw {
		// Stop at the first plainly textual rune: that is where the emoji ended.
		if unicode.IsLetter(r) || unicode.IsDigit(r) || unicode.IsSpace(r) {
			break
		}
		b.WriteRune(r)
		if b.Len() >= 8 { // custom_foods CHECK caps the emoji at 8 bytes
			break
		}
	}
	return strings.TrimSpace(b.String())
}

func clamp(v, lo, hi float64) float64 {
	if v != v { // NaN
		return lo
	}
	if v < lo {
		return lo
	}
	if v > hi {
		return hi
	}
	return v
}

func atLeastZero(v float64) float64 {
	if v != v || v < 0 {
		return 0
	}
	return v
}
