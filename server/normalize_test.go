package main

import (
	"reflect"
	"testing"
)

func TestNormalizeCollapsesRepeatedIDs(t *testing.T) {
	// A model that lists the same physical item twice in one reply would put two
	// rows on the plate and log the chicken twice. One id, one row.
	in := []Detection{
		{InstanceID: "chicken_1", Name: "Chicken thigh", Grams: 140, Confidence: 0.7, Shots: []int{1}},
		{InstanceID: "Chicken_1", Name: "Grilled chicken thigh", Grams: 160, Confidence: 0.9, Shots: []int{2, 3}},
	}

	got := normalizeDetections(in, 3, nil)

	if len(got) != 1 {
		t.Fatalf("want 1 item, got %d: %+v", len(got), got)
	}
	if got[0].InstanceID != "chicken_1" {
		t.Errorf("id = %q, want chicken_1", got[0].InstanceID)
	}
	// The higher-confidence row wins the scalar fields...
	if got[0].Name != "Grilled chicken thigh" || got[0].Grams != 160 {
		t.Errorf("scalars = %q/%v, want the higher-confidence row's", got[0].Name, got[0].Grams)
	}
	// ...and the shot lists union, which is what renders `↺ 3`.
	if !reflect.DeepEqual(got[0].Shots, []int{1, 2, 3}) {
		t.Errorf("shots = %v, want [1 2 3]", got[0].Shots)
	}
}

func TestNormalizeAdoptsStagedIDForTheSameFood(t *testing.T) {
	// The model minted a new id for food the request already named. Left alone,
	// that is a second chicken thigh on the plate and in the log.
	plate := []PlateItem{{InstanceID: "chicken_1", Name: "Chicken thigh", Grams: 140}}
	in := []Detection{
		{InstanceID: "chicken_thigh_2", Name: "Chicken thighs", Grams: 150, Confidence: 0.9, Shots: []int{2}},
	}

	got := normalizeDetections(in, 2, plate)

	if len(got) != 1 {
		t.Fatalf("want 1 item, got %d", len(got))
	}
	if got[0].InstanceID != "chicken_1" {
		t.Errorf("id = %q, want the staged chicken_1", got[0].InstanceID)
	}
}

func TestNormalizeKeepsTwoItemsOfOneFood(t *testing.T) {
	// Two physical eggs are two entries. The alias pass must not collapse them
	// just because they share a name — only an *unclaimed* staged id is adopted.
	plate := []PlateItem{{InstanceID: "egg_1", Name: "Fried egg", Grams: 50}}
	in := []Detection{
		{InstanceID: "egg_1", Name: "Fried egg", Grams: 50, Confidence: 0.9, Shots: []int{1, 2}},
		{InstanceID: "egg_2", Name: "Fried egg", Grams: 52, Confidence: 0.88, Shots: []int{2}},
	}

	got := normalizeDetections(in, 2, plate)

	if len(got) != 2 {
		t.Fatalf("want 2 items, got %d: %+v", len(got), got)
	}
	if got[0].InstanceID != "egg_1" || got[1].InstanceID != "egg_2" {
		t.Errorf("ids = %q/%q, want egg_1/egg_2", got[0].InstanceID, got[1].InstanceID)
	}
}

func TestNormalizeDropsUnusableEntries(t *testing.T) {
	in := []Detection{
		{InstanceID: "", Name: "Nameless id", Shots: []int{1}},
		{InstanceID: "!!!", Name: "Punctuation only id", Shots: []int{1}},
		{InstanceID: "ok_1", Name: "   ", Shots: []int{1}},
		{InstanceID: "ok_2", Name: "Real food", Shots: []int{1}},
	}

	got := normalizeDetections(in, 1, nil)

	if len(got) != 1 || got[0].InstanceID != "ok_2" {
		t.Fatalf("want only ok_2, got %+v", got)
	}
}

func TestNormalizeClampsNumbers(t *testing.T) {
	in := []Detection{{
		InstanceID:  "x_1",
		Name:        "Thing",
		Grams:       9001, // outside 1..2000
		Confidence:  1.8,
		Shots:       []int{3, 1, 1, 0, 9},
		Kcal100g:    -20,
		Protein100g: -1,
		Carb100g:    -0.7, // plausible for USDA, never for a model estimate
		Fat100g:     3,
	}}

	got := normalizeDetections(in, 3, nil)[0]

	if got.Grams != 0 {
		t.Errorf("grams = %v, want 0 to mean 'no usable estimate'", got.Grams)
	}
	if got.Confidence != 1 {
		t.Errorf("confidence = %v, want 1", got.Confidence)
	}
	if !reflect.DeepEqual(got.Shots, []int{1, 3}) {
		t.Errorf("shots = %v, want [1 3]", got.Shots)
	}
	for name, v := range map[string]float64{
		"kcal": got.Kcal100g, "protein": got.Protein100g, "carb": got.Carb100g,
	} {
		if v != 0 {
			t.Errorf("%s = %v, want 0: custom_foods CHECKs reject negatives", name, v)
		}
	}
	if got.Fat100g != 3 {
		t.Errorf("fat = %v, want 3 untouched", got.Fat100g)
	}
}

func TestNormalizeRoundsGrams(t *testing.T) {
	got := normalizeDetections(
		[]Detection{{InstanceID: "a", Name: "A", Grams: 137.6, Shots: []int{1}}}, 1, nil)[0]
	if got.Grams != 138 {
		t.Errorf("grams = %v, want 138", got.Grams)
	}
}

func TestNormalizeEmptyShotsBecomeTheNewestShot(t *testing.T) {
	got := normalizeDetections(
		[]Detection{{InstanceID: "a", Name: "A", Grams: 10, Shots: nil}}, 4, nil)[0]
	if !reflect.DeepEqual(got.Shots, []int{4}) {
		t.Errorf("shots = %v, want [4]", got.Shots)
	}
}

func TestNormalizeFallsBackToTheNameAsSearchTerm(t *testing.T) {
	got := normalizeDetections(
		[]Detection{{InstanceID: "a", Name: "Cherry tomatoes", SearchTerm: "  ", Shots: []int{1}}}, 1, nil)[0]
	if got.SearchTerm != "Cherry tomatoes" {
		t.Errorf("search term = %q, want the name", got.SearchTerm)
	}
}

func TestNormalizePreservesFirstSeenOrder(t *testing.T) {
	// The plate must not reshuffle between shots; a row that jumps position
	// under the user's finger is how a swipe removes the wrong food.
	in := []Detection{
		{InstanceID: "c", Name: "C", Shots: []int{1}},
		{InstanceID: "a", Name: "A", Shots: []int{1}},
		{InstanceID: "b", Name: "B", Shots: []int{1}},
		{InstanceID: "a", Name: "A again", Shots: []int{2}},
	}

	got := normalizeDetections(in, 2, nil)

	ids := []string{got[0].InstanceID, got[1].InstanceID, got[2].InstanceID}
	if !reflect.DeepEqual(ids, []string{"c", "a", "b"}) {
		t.Errorf("ids = %v, want [c a b]", ids)
	}
}

func TestSlugifyID(t *testing.T) {
	cases := map[string]string{
		"chicken_1":        "chicken_1",
		"Chicken Thigh #1": "chicken_thigh_1",
		"  --egg-- ":       "egg",
		"":                 "",
		"!!!":              "",
		"Ünïcode":          "n_code",
		"a very long identifier that goes on well past the forty byte cap": "a_very_long_identifier_that_goes_on_well",
	}
	for in, want := range cases {
		if got := slugifyID(in); got != want {
			t.Errorf("slugifyID(%q) = %q, want %q", in, got, want)
		}
	}
}

func TestNameKeyIgnoresOrderPunctuationAndPlurals(t *testing.T) {
	if a, b := nameKey("Cherry tomatoes"), nameKey("tomato, cherry"); a != b {
		t.Errorf("%q != %q", a, b)
	}
	if a, b := nameKey("Chicken thigh"), nameKey("Beef mince"); a == b {
		t.Errorf("unrelated names collided on %q", a)
	}
}

func TestFirstEmoji(t *testing.T) {
	cases := map[string]string{
		"🍗":         "🍗",
		"🍗 chicken": "🍗",
		"🍽️":        "🍽️",
		"":          "",
		"chicken":   "",
	}
	for in, want := range cases {
		if got := firstEmoji(in); got != want {
			t.Errorf("firstEmoji(%q) = %q, want %q", in, got, want)
		}
	}
	// custom_foods caps the column at 8 bytes.
	if got := firstEmoji("🍗🍗🍗🍗"); len(got) > 8 {
		t.Errorf("firstEmoji kept %d bytes, want at most 8", len(got))
	}
}
