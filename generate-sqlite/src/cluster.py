"""Stage 3b — group the corpus into items, each with its preparations.

The catalog carries one row per USDA record, so "Whole raw egg", "Poached egg",
"Boiled or poached egg" and "Fried egg, no added fat" are four foods where a
user sees one food in four preparations, and ground beef is nine foods at nine
fat levels. This stage builds the two-level structure the app shows: an **item**
(one row in the search list) holding one or more **preparations** (the variant
selector).

**Identity is a key here, not a pairwise test.** Stage 3b-1 (``canon.py``) has
already read each food's ``base_name`` — its identity with every preparation,
grade and trim word removed — so an item is just every food sharing a
``base_key`` and a ``food_kind``, the latter voted per identity by
:func:`_voted_kinds`. Being a key rather than a relation is the point: a key is
transitive for free, which is exactly what the greedy complete-linkage
machinery this replaced existed to fake.

What went away with it, and why (all measured on the 13,694-food corpus):

* **Token overlap** (Jaccard ≥ 0.70 over stopword-filtered description words).
  It cannot tell an ingredient word from a handling word, and the stopword list
  was the thing making the call: "granola bars, hard, plain" and "granola bars,
  hard, almond" scored 0.75 and became one item.
* **The protein:carb:fat ratio** (within 0.20 on the simplex). Macros are not
  an identity signal — the same food recorded in two USDA databases differs by
  more than two different foods do within one. 6,586 token-similar pairs were
  rejected by it, 698 of them cross-database duplicates of the same food.
* **The fat-free projection**, which existed only to rescue fat-level families
  from the ratio test. With no ratio test there is nothing to rescue: the
  numeric "% lean" is stripped from base_key, so every grade of ground beef
  keys alike on the way in.

Macros still do the one job they are good at. :func:`split_preps` separates an
item's preparations, seeded by the labels Stage 3b-1 read off the descriptions
and merged where the numbers say two labels are one preparation.
"""
from __future__ import annotations

import hashlib
import re
from functools import lru_cache

import inflect
import polars as pl

from . import config

_INFLECT = inflect.engine()

# Words are letters only: digits and punctuation carry no identity ("Grade A"
# is a grade), and stripping them is also what folds "80% lean" out of a base
# name — see _FAT_LEVEL_RE, which runs first so the number goes with its unit.
_WORD_RE = re.compile(r"[a-z]+")

# A stated numeric fat level, dropped before keying. Every grade of ground beef
# and every fat level of milk is one item sold at several grades, so they have
# to key alike; canon.py is told not to emit these, and this is the guarantee.
_FAT_LEVEL_RE = re.compile(r"\d+(\.\d+)?\s*%\s*(lean|fat|milkfat)?")


@lru_cache(maxsize=None)
def _singular(word: str) -> str:
    """Singularize one identity word: 'eggs' -> 'egg', 'potatoes' -> 'potato'.

    This stripped a trailing "s" by hand, on the stated grounds that a stemmer
    would be a dependency for one rule. Re-measured, that trade was wrong and
    is reversed here: stripping the "s" makes "potatoes" into "potatoe" while
    "potato" stays itself, so the two never meet. On the 13,694-food corpus
    that cost 11 items — potato, jelly, maraschino cherry, sun-dried tomato,
    hush puppy, peach and pork foot/feet among them. Swapping in ``inflect``
    takes the corpus from 6,809 items to 6,798 and splits no existing item:
    every merge is a plural meeting its singular.

    The ss/us/is guard stays and it is the load-bearing part, not the library
    call: unguarded, ``inflect`` maps "glass" to "glas" while "glasses" maps to
    "glass", and it mangles asparagus, hummus, couscous and watercress. The
    guard is narrow rather than complete — "ramen" still becomes "raman" — and
    that is tolerable because the output need not be a real word, only the
    *same* word for both forms of one food. So "molasses", which ends "es" and
    so runs past the guard, folding to "molass" is fine: no other form of it
    exists in the corpus, and nothing else folds onto it.

    Memoized because it runs once per word per identity: 39.4k calls over 2.3k
    distinct words, which is 4.4 s of Stage 3b against 1.0 s memoized, on a
    stage the README budgets at ~2 s.
    """
    if len(word) < 4 or word.endswith(("ss", "us", "is")):
        return word
    return _INFLECT.singular_noun(word) or word


def _key_words(base_name: str) -> list[str]:
    """The identity words :func:`base_key` keys on, in the order they were written.

    Split out because :func:`spelling_splits` needs everything base_key does
    *except* the sort — the sort is the very thing it is measuring the cost of.
    """
    text = _FAT_LEVEL_RE.sub(" ", base_name.lower())
    return [w for w in (_singular(w) for w in _WORD_RE.findall(text))
            if w not in config.BASE_KEY_STOPWORDS]


def base_key(base_name: str | None) -> str:
    """Normalize a base_name into the string items are grouped by.

    Absorbs the ways an LLM can write the same identity differently across two
    requests — case, plural, punctuation, word order — so "Rice, white",
    "white rice" and "White Rices" are one item. That is the residual risk this
    pass exists to cover: batching in canon.py is what makes the model *write*
    one string for a food's several records, and this is what makes near-misses
    survive anyway.

    Sorting the tokens is what handles word order, and it is safe precisely
    because a base_name has already been stripped to identity words: no food in
    this corpus is distinguished from another only by the order of the same
    words.

    Returns "" for an empty name, which the caller must not treat as a key —
    see :func:`_row`.
    """
    if not base_name:
        return ""
    return " ".join(sorted(set(_key_words(base_name))))


_RAW_WORDS = frozenset({"raw", "unprepared", "uncooked"})


def prep_label(
    prep: str | None, description: str | None, base_name: str | None, food_kind: str | None
) -> str | None:
    """Correct the two preparation mistakes Stage 3b-1 makes systematically.

    A twin of :func:`base_key`: pure, no database, called by
    ``store.apply_canonicalization`` to derive a stored column, so no write path
    can bypass it. Measured on the 13,694-food corpus it moves 328 records — 145
    off ``cooked`` onto the label their own description states, 183 off nothing
    onto ``raw`` — and leaves the other 13,366 exactly as the model wrote them.
    The spec's figure for the second branch was 187; the four it declines are
    records the model wrote "raw cranberries" and "raw vegetable" for, where the
    state word IS the identity it was given, and declining on them is the third
    limit below doing its job rather than a shortfall.

    It fires in two situations and declines everywhere else. Three limits are
    what make it safe:

    * **It only ever replaces ``cooked`` or nothing.** A specific label the
      model already chose is never overridden, so the cases text alone gets
      wrong are never reached: "roast" as a cut name, "frozen" versus
      "microwaved" precedence, "dry" versus "dried", "kippered". Deriving
      preparation wholly from text was measured at 777 records changed and 786
      wrongly emptied; this is the subset that is unambiguous.
      The blank branch is the one place where that limit is thinner than it
      reads, because "nothing" is not a choice: 41 of its 183 hits also state
      ``frozen`` or ``dried`` ("Asparagus, frozen, unprepared"), and they take
      ``raw``. That is the stated rule — an unprepared food IS raw, and the
      alternative is precedence between two text signals, which is the thing
      measured at 786 wrong answers.
    * **Exactly one named child, or it declines.** "Chicken breast, baked,
      broiled, or roasted" keeps ``cooked``, which is the right answer and what
      the catch-all label exists for.
    * **The food's own identity is subtracted from its description**, which is
      what stops "fried rice" being relabelled ``fried``. That reuses the
      model's identity judgment rather than re-deriving it — "words that are
      part of the dish's NAME even though they look like cooking" is already a
      rule in the canon.py prompt.

    The subtraction compares raw words, NOT :func:`base_key` output: base_key
    singularizes through ``inflect``, and a cooking participle put through a
    noun singularizer no longer matches the enum label it has to be looked up
    by. Both sides use the same plain split, so the symmetry that makes the
    subtraction work is kept without touching the labels.

    ``fresh`` is deliberately not read as ``raw`` — it produces "Cheese, fresh,
    queso fresco" and "Pasta, fresh-refrigerated", which are not raw foods — and
    the phrase "from raw" is excluded because it says what a *cooked* food was
    made from.
    """
    text = (description or "").lower()
    stated = set(_WORD_RE.findall(text)) - set(_WORD_RE.findall((base_name or "").lower()))
    if prep == "cooked":
        named = {p for p in stated if config.PREP_PARENT.get(p) == prep}
        return named.pop() if len(named) == 1 else prep
    if (prep is None and food_kind == "ingredient" and "from raw" not in text
            and _RAW_WORDS & stated):
        return "raw"
    return prep


def _prep_vector(macros: tuple[float, float, float], variable_fat: bool) -> tuple[float, ...]:
    """What the preparation split compares — per 100 g, or per 100 g of lean.

    For an ordinary item that is the three macros as they are. For a fat-level
    family it cannot be: leanness moves fat and protein together, so raw ground
    beef ranges over 27.5 g to 3.0 g of fat and 15.1 g to 22.0 g of protein,
    and comparing those directly splits one preparation into eight "preps" that
    are only fat levels. Measured, this basis takes the cooked patty group from
    6 preparations to 1 and raw ground beef from 8 to 2, while leaving chicken
    thigh and egg alone.
    """
    protein, carb, fat = macros
    if not variable_fat:
        return (protein, carb, fat)
    lean = max(1.0, 100.0 - fat)
    return (protein * 100 / lean, carb * 100 / lean)


def _prep_distance(a: tuple[float, ...], b: tuple[float, ...]) -> float:
    """Worst macro's relative gap, floored so near-zero macros stay comparable."""
    return max(abs(x - y) / max(config.PREP_FLOOR_G, x, y) for x, y in zip(a, b))


def is_variable_fat(group: list[dict]) -> bool:
    """True when the item spans fat levels rather than sitting at one point.

    A stated fat level (Stage 2's ``fat_percentage`` regex) is the whole test.
    It has to be deterministic and it has to be known before the LLM runs,
    because :func:`_prep_vector` changes basis on the answer.
    """
    return any(r["fat_level"] for r in group)


def _mean(rows: list[dict], i: int) -> float:
    return sum(r["macros"][i] for r in rows) / len(rows)


def _parent(label: str | None) -> str | None:
    """The widest label that still describes this one. Its own, if it has none."""
    return config.PREP_PARENT.get(label, label) if label else None


def _compatible(a: set[str | None], b: set[str | None]) -> bool:
    """Whether two preparation buckets are even allowed to merge.

    The macro test may only merge *within* a label family, and that ceiling is
    load-bearing. Poaching an egg barely moves its per-100 g macros, so raw and
    poached egg sit inside PREP_DISTANCE of each other — and merging them
    produces one preparation holding raw eggs under the label "poached", which
    is worse than the extra row it saves. Grilled and baked chicken land on the
    same numbers too, but they share the parent "cooked", so merging them
    yields a label that is true of both.

    A null label is compatible with anything: the description not saying how a
    food was prepared is an absence of evidence, so the macros are all there is
    to go on and they are allowed to decide.
    """
    pa = {_parent(x) for x in a} - {None}
    pb = {_parent(x) for x in b} - {None}
    return not pa or not pb or pa == pb


def _widest_label(labels: set[str | None]) -> str | None:
    """One label for the preparations that merged.

    ``_compatible`` guarantees every named label here shares a parent, so
    "grilled" and "baked" together become "cooked" while a bucket that only
    ever held "broiled" keeps the more informative "broiled".

    A null label loses to any real one: the sibling that states a preparation
    describes the bucket better than the one that is silent about it.
    """
    named = {label for label in labels if label}
    if not named:
        return None
    return named.pop() if len(named) == 1 else _parent(min(named))


def _absorb_vague_cooked(
    preps: list[tuple[str | None, list[dict]]],
) -> list[tuple[str | None, list[dict]]]:
    """Fold a vague "cooked" preparation into its one named sibling.

    An item must never ask a user to choose between "cooked" and "boiled",
    which mean the same thing. Asparagus offers exactly that: a "cooked"
    preparation no member of which states a method, beside a "boiled" one. The
    specific name wins, because the item does specify — which is the whole
    reason "cooked" is reserved as the fallback in the first place.

    The two cases are told apart rather than merged unconditionally, and that
    distinction is the point of this function, not an exception to it. A
    "cooked" label is reached two ways. Either no member said how (asparagus,
    bamboo shoot), and then it carries no information its named sibling does not
    — 59 items. Or :func:`_widest_label` *widened* it from two or more members
    that each named a method — back chicken from roasted + stewed, beside
    fried; lamb shoulder from broiled + roasted, beside braised — and there it
    honestly means "cooked some other way", so absorbing it into "fried" would
    file roasted chicken under a label that is false of it. Which case an item
    is in is readable off its members' own labels, so the same shape as the
    guard in :func:`prep_label` applies: act where the evidence is unambiguous,
    decline where it is not.

    Several named siblings decline for the same reason: with "cooked" beside
    both "fried" and "boiled" there is no one specific name to take, and
    picking either would be a coin toss the user pays for. Both sides are
    counted and both must be exactly one. Only the named side can be several
    today — bucketing is by exact label, so at most one preparation can be
    vaguely "cooked" — but a take-the-first on the other side would answer a
    question it had not checked, and this function's whole rule is that an
    ambiguous count declines.

    Measured over the shipped 13,694-food corpus with the :func:`prep_label`
    guard applied (the stored column is backfilled by #22, not here): 99 items
    offered "cooked" beside a specific method, 59 are absorbed and 40 keep it.
    The spec projected 94 / 53 / 41 from a simulation that also assumed the
    re-canonicalization prompt had landed, which it has not. The corpus itself
    is the one the spec measured — without the guard it reproduces that
    baseline of 83 exactly — so the gap is in what the guard alone does to it,
    and every extra item it sharpens into a named sibling is one more this
    absorbs. Nothing is tuned to the projection: the rule is the rule and these
    are the numbers it produces.

    Deliberately ignores the macro distance that separated the two buckets. The
    labels are the evidence here — the numbers only ever decided *which* rows
    share a preparation, never what a preparation is called.
    """
    vague = [
        i for i, (label, rows) in enumerate(preps)
        if label == "cooked"
        and not any(config.PREP_PARENT.get(r["prep_label"]) == "cooked" for r in rows)
    ]
    named = [i for i, (label, _) in enumerate(preps) if config.PREP_PARENT.get(label) == "cooked"]
    if len(vague) != 1 or len(named) != 1:
        return preps
    child = named[0]
    rows = sorted(preps[child][1] + preps[vague[0]][1],
                  key=lambda r: (-sum(r["macros"]), r["fdc_id"]))
    return [(label, rows if i == child else members)
            for i, (label, members) in enumerate(preps) if i != vague[0]]


def split_preps(group: list[dict]) -> list[tuple[str | None, list[dict]]]:
    """Split one item into (label, members) preparations. Labels first, macros second.

    The order matters and it is the fix for a real failure. Splitting on macros
    alone — as this did — meant the same food recorded in two USDA databases
    with different numbers became two preparations, and the LLM was then asked
    to invent a distinction between them that does not exist. Bucketing by the
    label Stage 3b-1 read off each description puts them together first, and
    the macro pass only ever *merges* buckets from there.

    So a bucket survives as its own preparation only when both its text and its
    numbers say it is different, and the merge itself is capped by
    :func:`_compatible` — macros may join "grilled" to "baked" but never "raw"
    to "poached". Complete-linkage on the merge, so a merged bucket stays
    macro-coherent rather than chaining.

    Then :func:`_absorb_vague_cooked` runs, which is the one merge the macros do
    not get a vote on: a "cooked" preparation nobody stated a method for, beside
    exactly one named sibling, is that sibling under a vaguer name.

    Ordered by descending total macros, so the most concentrated preparation is
    seq 0 — dried before cooked before raw, which is stable and happens to read
    well in the selector.
    """
    variable_fat = is_variable_fat(group)
    buckets: dict[str | None, list[dict]] = {}
    for row in group:
        buckets.setdefault(row["prep_label"], []).append(row)

    # Merge buckets whose macros agree. Sorted by descending concentration so
    # the pass is deterministic; None last, so a stated label always seeds a
    # bucket before the unlabeled rows are asked to join one.
    merged: list[list[list[dict]]] = []
    for label in sorted(buckets, key=lambda k: (k is None, -_mean(buckets[k], 0), k or "")):
        rows = buckets[label]
        vector = _prep_vector(tuple(_mean(rows, i) for i in range(3)), variable_fat)
        for prep in merged:
            if _compatible({label}, {r["prep_label"] for o in prep for r in o}) and all(
                _prep_distance(
                    vector,
                    _prep_vector(tuple(_mean(other, i) for i in range(3)), variable_fat),
                ) <= config.PREP_DISTANCE
                for other in prep
            ):
                prep.append(rows)
                break
        else:
            merged.append([rows])

    preps = [
        (
            _widest_label({r["prep_label"] for bucket in prep for r in bucket}),
            sorted((r for bucket in prep for r in bucket),
                   key=lambda r: (-sum(r["macros"]), r["fdc_id"])),
        )
        for prep in merged
    ]
    preps = _absorb_vague_cooked(preps)
    preps.sort(key=lambda p: (-sum(_mean(p[1], i) for i in range(3)), p[1][0]["fdc_id"]))
    return preps


def representative(rows: list[dict]) -> dict:
    """The member whose fdc_id addresses a preparation (and so an item).

    Widest nutrient panel first: every member is within PREP_DISTANCE on the
    macros by construction, so nutrition cannot decide it, but the detail page
    shows the full panel and a Foundation row with 60 nutrients is visibly
    better than an FNDDS row with 6. Then shortest description, then fdc_id, so
    the choice — and therefore merged_food_id — is stable across re-runs.
    """
    return min(rows, key=lambda r: (-r["n_nutrients"], len(r["description"]), r["fdc_id"]))


def member_key(rows: list[dict]) -> str:
    """A short stable digest of an item's membership.

    Stage 4's queue predicate keys off this: when re-clustering changes who is
    in a group, its LLM naming is stale and the row goes back in the queue.
    Comparing membership directly would mean storing the whole list.
    """
    joined = ",".join(str(fdc_id) for fdc_id in sorted(r["fdc_id"] for r in rows))
    return hashlib.blake2b(joined.encode(), digest_size=16).hexdigest()


def _row(record: dict) -> dict:
    """One frame row as the clustering functions want it.

    The ``base_key`` fallback is what keeps this stage runnable on a corpus
    Stage 3b-1 has not covered yet — a food with no identity keys on its own
    fdc_id and forms a singleton item, which is visible in the counts and fixed
    by running the canonicalization pass. Guessing an identity from the
    description instead would be worse than useless: a wrong key merges two
    foods that should stay apart, where a missing one only fails to merge.
    """
    macros = tuple(float(record[k] or 0.0) for k in config.MERGE_MACRO_KEYS)
    key = base_key(record.get("base_name"))
    return {
        "fdc_id": record["fdc_id"],
        "description": record["description"],
        "food_category": record["food_category"],
        "brand_flagged": bool(record["brand_flagged"]),
        "n_nutrients": int(record["n_nutrients"] or 0),
        "base_key": key or f"\x00{record['fdc_id']}",
        # The identity as it was written, which base_key deliberately flattens.
        # Kept so the diagnostics can measure what that flattening covered up.
        "base_name": record.get("base_name"),
        "food_kind": record.get("food_kind") or "",
        "prep_label": record.get("prep_label"),
        "macros": macros,
        # Stage 2 parsed a "% lean"/"% fat"/"% milkfat" out of the name.
        "fat_level": record["fat_percentage"] is not None,
    }


def _voted_kinds(rows: list[dict]) -> dict[str, str]:
    """The one ``food_kind`` each disagreeing identity is grouped under.

    Only identities whose records disagree appear here, and only where the vote
    is allowed to run — everything else keeps the kind its own record carries,
    so this is a small override map rather than a second copy of the key.

    **A disagreement is model noise, not a distinction.** An identity whose
    records straddle a canonicalization batch boundary comes back "ingredient"
    in one batch and "dish" in the next, and then splits into two search rows
    for one food. Inspected across the whole corpus, not one of the 121 such
    identities was a real ingredient-versus-dish call: broccoli is 22
    ingredient records against 1 dish ("Broccoli, cooked, as ingredient"), plum
    14 against 1, asparagus 13 against 11. So the majority wins, ties break to
    "ingredient", and the item is whole again. The tiebreak is spelled out in
    the sort key rather than left to ride on "ingredient" sorting after "dish",
    which would silently become a different rule if a third kind were ever
    added to ``config.FOOD_KINDS``.

    **Except where :func:`spelling_splits` flags the identity**, where it
    declines and the split stands. That exemption is the safety gate and it is
    the reason a vote is safe at all: the identities most likely to hold two
    genuinely different foods are exactly the ones ``base_key``'s token sort
    merged, and there the kind is the only thing keeping them apart.
    ``chocolate milk`` is that identity — "Candies, milk chocolate" keys onto
    the beverage — and the gate is why a 535 kcal confectionery record does not
    join the seven fluid-milk records the vote would otherwise have pulled it
    in with. It does not *undo* the collision: that record already shares an
    item with the twelve FNDDS "Chocolate milk, ..." rows that agree with it on
    "ingredient", which is the 13-member group #14 describes and which only the
    canonicalization prompt can separate. The gate's job is to not make it
    twenty.

    Measured on the shipped 13,694-food corpus: 121 identities disagree, 8 of
    them are spelling-flagged and keep their split, and the other 113 are voted
    into one item each — 6,798 items to 6,685, moving 675 foods and nothing
    outside those 113 identities. 47 of the 113 were exact ties and all took
    "ingredient". The spec projected 120 disagreeing and 0 remaining; the 121 is
    the corpus at HEAD (#16's plural fold merged one more identity — the same
    drift :func:`spelling_splits` measured), and the 8 are the gate doing its
    job rather than a shortfall: the two sets were assumed disjoint and are not.

    Derived here on every run, never written: the stored ``food_kind`` stays
    exactly what Stage 3b-1 said about that one record, so this is re-derivable
    after a re-canonicalization and costs nothing to change. The price is that
    Stage 4 is sent the kind of the item's *representative* — 42 of the 113
    voted items are represented by a minority-kind record, and their naming
    request says "dish" where the item was voted "ingredient". Sending the vote
    instead would mean either writing it down or teaching the enrichment query
    to re-derive it in SQL; the field is real per record and this is the one
    place that reads it per record.
    """
    exempt = spelling_splits(rows)
    kinds: dict[str, list[str]] = {}
    for row in rows:
        kinds.setdefault(row["base_key"], []).append(row["food_kind"])
    return {
        key: max(set(votes), key=lambda k: (votes.count(k), k == "ingredient", k))
        for key, votes in kinds.items()
        if len(set(votes)) > 1 and key not in exempt
    }


def build_groups(rows: list[dict]) -> list[list[dict]]:
    """Partition foods into items: one per (base_key, voted food_kind).

    ``food_kind`` is in the key and is not decoration: it is the rule that a
    dish is never a preparation of the ingredient it is made of, which is what
    keeps "fried rice" out of "white rice".

    It is read per identity rather than per row, and :func:`_voted_kinds` is
    what reads it. Where an identity's own records disagree about their kind
    the disagreement is the model contradicting itself rather than a
    distinction, so the majority decides for all of them and the food is one
    item again. The guard survives where it is load-bearing: an identity whose
    members are written more than one way is exempt from the vote, so a
    collision the token sort created is still split on kind alone.

    Sorted output so the item order — and therefore nothing at all, but also
    every diagnostic that prints it — is reproducible across runs.
    """
    voted = _voted_kinds(rows)
    groups: dict[tuple[str, str], list[dict]] = {}
    for row in rows:
        key = row["base_key"]
        groups.setdefault((key, voted.get(key, row["food_kind"])), []).append(row)
    return [groups[k] for k in sorted(groups)]


def kind_splits(rows: list[dict]) -> list[str]:
    """base_keys still split by a disagreement the vote declined to resolve.

    Not every identity whose records disagree: those are voted and merged by
    :func:`_voted_kinds`. What is left here is the residue the safety gate
    holds back — an identity that both disagrees about its kind *and* was
    written more than one way, where merging could join two different foods
    rather than one food's two halves. 8 identities on the 13,694-food corpus,
    down from 121 before the vote, and ``chocolate milk`` is one of them.

    So it stays a defect worth reading, but a different one: it now counts
    duplicate rows the pipeline has deliberately chosen over a possible wrong
    merge, and the fix is the canonicalization prompt writing one spelling per
    identity — which empties this list through :func:`spelling_splits` rather
    than by agreeing about the kind.
    """
    kinds: dict[str, set[str]] = {}
    for row in rows:
        kinds.setdefault(row["base_key"], set()).add(row["food_kind"])
    voted = _voted_kinds(rows)
    return sorted(k for k, v in kinds.items() if len(v) > 1 and k not in voted)


def spelling_splits(rows: list[dict]) -> set[str]:
    """base_keys whose members were written more than one way.

    A **set**, not a count, and that is the point of it: the identities in here
    are the ones :func:`base_key`'s token sort merged, so they are the ones most
    likely to hold two genuinely different foods — "chocolate milk" the drink
    and "milk chocolate" the confectionery are one key. Anything that wants to
    *resolve* a disagreement inside an identity has to be able to ask whether
    this is one of them and decline; a number cannot answer that.

    Measured as ``base_key`` minus the sort — same lowercasing, fat-level strip,
    singularization and stopwords, order kept — because the sort is the whole
    mechanism being measured. Two members whose words differ outright ("beef
    stew" vs "beef stew, canned") cannot share a key in the first place, so
    every entry here really is one identity written two ways.

    Keyed on ``base_key`` alone, unlike :func:`leaked_cooking_words` and unlike
    the grouping itself, and that is required rather than an oversight: what
    consumes this is a caller asking whether an identity whose records disagree
    about ``food_kind`` is safe to merge, so the two kinds' spellings have to be
    compared with each other. Per (key, kind) the confectionery record sits
    alone with one spelling and the collision it is the whole example of would
    not be flagged.

    35 identities on the 13,694-food corpus. Run against the corpus as it stood
    before ``inflect`` landed (#16) this rule returns exactly the 34 the spec
    measured; the extra one is a plural pair the hand-rolled trailing-s rule
    kept apart and inflect now folds into one identity, which is that change
    working rather than a regression here.
    """
    spellings: dict[str, set[tuple[str, ...]]] = {}
    for row in rows:
        if row["base_name"]:
            spellings.setdefault(row["base_key"], set()).add(
                tuple(dict.fromkeys(_key_words(row["base_name"])))
            )
    return {key for key, written in spellings.items() if len(written) > 1}


# Every word the preparation enum knows, which is this corpus's own vocabulary
# for how a food was handled. Deliberately not a hand-maintained list of
# "cooking words": the 60-word stopword list this pipeline already deleted is
# what that becomes, and the cost of the enum instead is that a leak the enum
# has no word for ("heated", "refrigerated") is invisible here.
_PREP_WORDS = frozenset(config.PREP_TYPES)


def leaked_cooking_words(rows: list[dict]) -> list[str]:
    """base_keys carrying a preparation word that cost them a duplicate item.

    Stage 3b-1 is told a cooking method is never identity unless the dish is
    named for it ("fried rice", "baked beans"), and 719 records still leak one.
    Only some of those leaks *cost* anything, and this counts those: an identity
    is listed when dropping the leaked word lands on another identity that
    really exists, at the same ``food_kind`` — which is exactly the item the
    leak split it away from. "grilled cheese sandwich" beside "cheese sandwich"
    is in here and is a *correct* split, one of the ten or so the spec measured
    a blind strip getting wrong; that is why this is reported and never
    auto-stripped, a wrong merge being worse than a missed one.

    161 identities on the 13,694-food corpus, against the spec's 173. That
    figure came from an ad-hoc strip during the grilling session and its word
    list did not survive into the repo, so this is not the same rule counted
    twice. Three differences, all deliberate: it counts identities where the
    spec counted *pairs*, so an identity leaking two words is one entry here;
    it keys off the preparation enum, which #15 has since taken "breaded" out
    of and put "brewed" into; and it requires the identity it would merge with
    to share a ``food_kind``, since two kinds are two items whatever the words
    say. Run over the corpus as it stood before #15 and #16 it returns 170.
    Reading it: it falls when the prompt stops leaking, and the residue is the
    genuinely method-named dishes.

    The stripped identity goes back through :func:`base_key` rather than being
    re-joined by hand, so the one normalization stays the only thing that knows
    what a key looks like.
    """
    identities = {(row["base_key"], row["food_kind"]) for row in rows}
    return sorted({
        key
        for key, kind in identities
        for word in _PREP_WORDS & set(key.split())
        if (base_key(" ".join(set(key.split()) - {word})), kind) in identities
    })


def unstated_preps(df: pl.DataFrame, preps: pl.DataFrame, links: pl.DataFrame) -> int:
    """Preparations holding a food whose description never stated a preparation.

    A bucket seeded by a label may take in rows that carry none — that is
    :func:`_compatible` treating a null label as an absence of evidence and
    letting the macros decide — and the food is then displayed under a name its
    own description never claimed. Raw carrots sitting under "boiled" is this
    count, and every one of them is a preparation whose label is inference from
    macros alone.

    194 preparations of 7,855 on the 13,694-food corpus, against the spec's 189.
    Over the corpus as it stood before ``inflect`` (#16) moved item membership
    and before the absorption rule (#18) merged buckets it is 192; the residual
    three are the spec's own margin, measured by hand in the session.

    Counts a member that *stated nothing*, not one whose stated label differs
    from the bucket's. The difference is #18: absorption deliberately files a
    vaguely "cooked" record under its one specific sibling, which is a record
    under a label it did not state and is the fix rather than the defect —
    counting it would make this rise by 45 because a correction landed.
    """
    member_labels = links.join(df.select("fdc_id", "prep_label"), on="fdc_id").join(
        preps.select("prep_id", "prep_type"), on="prep_id"
    )
    return member_labels.filter(
        pl.col("prep_type").is_not_null() & pl.col("prep_label").is_null()
    )["prep_id"].n_unique()


def build_clusters(df: pl.DataFrame) -> tuple[pl.DataFrame, pl.DataFrame, pl.DataFrame]:
    """Group a foods frame into (items, preps, links) frames. Pure.

    Expects columns fdc_id, description, food_category, fat_percentage,
    brand_flagged, n_nutrients, base_name, food_kind, prep_label and the three
    macro columns named by config.MERGE_MACRO_KEYS.
    """
    rows = [_row(r) for r in df.iter_rows(named=True)]
    items, preps, links = [], [], []

    for group in build_groups(rows):
        prep_groups = split_preps(group)
        # The largest preparation's representative addresses the whole item, so
        # the search list shows the macros of the form most USDA records
        # describe. max() keeps the first on a tie, which is the most
        # concentrated one.
        default = representative(max(prep_groups, key=lambda p: len(p[1]))[1])

        items.append({
            "merged_food_id": default["fdc_id"],
            "member_key": member_key(group),
            "n_foods": len(group),
            "n_preps": len(prep_groups),
            "food_category": default["food_category"],
            "variable_fat": is_variable_fat(group),
            "brand_flagged": any(r["brand_flagged"] for r in group),
        })
        for seq, (label, prep) in enumerate(prep_groups):
            head = representative(prep)
            preps.append({
                "prep_id": head["fdc_id"],
                "merged_food_id": default["fdc_id"],
                "seq": seq,
                "n_foods": len(prep),
                "prep_type": label,
                **{key: _mean(prep, i) for i, key in enumerate(config.MERGE_MACRO_KEYS)},
            })
            links.extend(
                {
                    "fdc_id": r["fdc_id"],
                    "merged_food_id": default["fdc_id"],
                    "prep_id": head["fdc_id"],
                }
                for r in prep
            )

    return (
        pl.DataFrame(items, schema={
            "merged_food_id": pl.Int64, "member_key": pl.Utf8, "n_foods": pl.Int32,
            "n_preps": pl.Int32, "food_category": pl.Utf8, "variable_fat": pl.Boolean,
            "brand_flagged": pl.Boolean,
        }),
        pl.DataFrame(preps, schema={
            "prep_id": pl.Int64, "merged_food_id": pl.Int64, "seq": pl.Int32,
            "n_foods": pl.Int32, "prep_type": pl.Utf8, "protein_g": pl.Float64,
            "carb_g": pl.Float64, "fat_g": pl.Float64,
        }),
        pl.DataFrame(links, schema={
            "fdc_id": pl.Int64, "merged_food_id": pl.Int64, "prep_id": pl.Int64,
        }),
    )


def load_candidates(con) -> pl.DataFrame:
    """Every food with its identity and its three macros pivoted out of
    food_nutrients."""
    from . import store

    macros = store.pivot_columns_sql(config.merge_macro_nutrients())
    return con.execute(
        f"""
        WITH m AS (
            SELECT fdc_id, {macros}, count(*) AS n_nutrients
            FROM food_nutrients GROUP BY fdc_id
        )
        SELECT f.fdc_id, f.description, f.food_category, f.fat_percentage,
               f.brand_flagged, f.base_name, f.food_kind, f.prep_label,
               coalesce(m.n_nutrients, 0) AS n_nutrients,
               {", ".join(f"m.{k}" for k in config.MERGE_MACRO_KEYS)}
        FROM foods f LEFT JOIN m USING (fdc_id)
        ORDER BY f.fdc_id
        """
    ).pl()


def run(con) -> dict:
    """Stage 3b driver: rebuild merged_foods, merged_preps and the foods links."""
    from . import store

    df = load_candidates(con)
    if df.is_empty():
        return {"foods": 0, "items": 0, "preps": 0}
    rows = [_row(r) for r in df.iter_rows(named=True)]
    items, preps, links = build_clusters(df)
    written = store.write_clusters(con, items, preps, links)
    return {
        "foods": len(df),
        "items": len(items),
        "preps": len(preps),
        "uncanonicalized": int(df["base_name"].is_null().sum()),
        "kind_splits": kind_splits(rows),
        # Corpus quality, so drift is a number that moves rather than something
        # found months later. A set, not a size — see :func:`spelling_splits`.
        "spelling_splits": spelling_splits(rows),
        "leaked_cooking_words": leaked_cooking_words(rows),
        "unstated_preps": unstated_preps(df, preps, links),
        "dishes": int((df["food_kind"] == "dish").sum()),
        "multi_food_items": int((items["n_foods"] > 1).sum()),
        "multi_prep_items": int((items["n_preps"] > 1).sum()),
        "variable_fat": int(items["variable_fat"].sum()),
        "largest_item": int(items["n_foods"].max()),
        **written,
    }
