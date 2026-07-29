/// Deciding whether a detected food is a food the catalog carries.
///
/// Pure: no SQL, no drift, no providers. The candidate list arrives from
/// `CatalogRepository.searchPrimary`, and everything here is a string comparison
/// over the names that came back.
///
/// Why similarity is computed in Dart rather than read off the SQL score: bm25
/// magnitudes are query-dependent — `chicken` spans 0.37 across its hits while
/// `chicken brea` spans 2.35 — so there is no single score threshold that means
/// "close enough" for both. Name similarity is comparable across queries.
library;

import '../../home/data/catalog_repository.dart';

/// How similar a detected name and a catalog name must be before the catalog row
/// is used. Below it, the detector's own name and macros are used instead, which
/// is the honest answer: a wrong catalog row is worse than an approximate one.
///
// ponytail: 0.6 is a judgement, not a measurement. Known casualty: `Olive oil`
// against USDA's `Oil, olive, salad or cooking` scores 0.57 and falls through to
// a generated food, which logs plausible numbers under a name the user typed
// nothing for. The upgrade path is scoring against `catalog.foods.aka` — which
// already holds USDA synonyms and is what makes "hot dog" find *Frankfurter* —
// and retuning this against a corpus of real replies.
const matchThreshold = 0.6;

/// Tokens of a food name, lowercased, punctuation-free and singularised.
///
/// Singularisation is folded only on tokens long enough that the suffix is
/// unlikely to be part of the word, so `oats` does not collide with `oat`'s
/// neighbours through a two-letter stem.
List<String> normalizeName(String raw) {
  final tokens = raw
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty);
  return [
    for (final t in tokens)
      if (t.length > 4 && t.endsWith('es'))
        t.substring(0, t.length - 2)
      else if (t.length > 3 && t.endsWith('s') && !t.endsWith('ss'))
        t.substring(0, t.length - 1)
      else
        t,
  ];
}

/// Sørensen–Dice over the two token *sets*, in 0.0–1.0.
///
/// Set-based rather than sequence-based because catalog descriptions invert word
/// order routinely — `Cherry tomatoes` against `Tomatoes, cherry` has to score 1,
/// and any positional metric scores it near 0.
double matchScore(String a, String b) {
  final left = normalizeName(a).toSet();
  final right = normalizeName(b).toSet();
  if (left.isEmpty || right.isEmpty) return 0;
  final shared = left.intersection(right).length;
  return 2 * shared / (left.length + right.length);
}

/// The best candidate for [name], or null when none clears [matchThreshold].
///
/// The comparison is strictly greater, so a tie keeps the order SQL returned:
/// the composite rank has already decided which of two equally-similar rows is
/// the better food, and it knows about commonness, preparation and what this user
/// logs, none of which a name comparison can see.
FoodHit? bestMatch(String name, List<FoodHit> candidates) {
  FoodHit? best;
  var bestScore = 0.0;
  for (final candidate in candidates) {
    final score = matchScore(name, candidate.name);
    if (score > bestScore) {
      bestScore = score;
      best = candidate;
    }
  }
  return bestScore >= matchThreshold ? best : null;
}
