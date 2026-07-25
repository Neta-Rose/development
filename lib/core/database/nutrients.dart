/// The 50 nutrient columns shared verbatim by `catalog.food_nutrition`,
/// `custom_foods` and `log_entries` — verified identical, in the same order.
///
/// Every value is per 100 g of edible portion. A real amount is always
/// `grams / 100.0 * <column>`.
///
/// These exist as a list rather than 50 Dart fields because the app never needs
/// the vector as an object: it is copied catalog → log and rolled up
/// ingredients → recipe entirely inside SQL, so the only thing required is the
/// column names.
const nutrientColumns = <String>[
  'energy_kcal',
  'protein_g',
  'fat_g',
  'carb_g',
  'fiber_g',
  'sugar_g',
  'starch_g',
  'water_g',
  'ash_g',
  'alcohol_g',
  'sat_fat_g',
  'mono_fat_g',
  'poly_fat_g',
  'trans_fat_g',
  'cholesterol_mg',
  'omega3_epa_g',
  'omega3_dha_g',
  'calcium_mg',
  'iron_mg',
  'magnesium_mg',
  'phosphorus_mg',
  'potassium_mg',
  'sodium_mg',
  'zinc_mg',
  'copper_mg',
  'manganese_mg',
  'selenium_ug',
  'fluoride_ug',
  'iodine_ug',
  'vitamin_a_rae_ug',
  'retinol_ug',
  'carotene_beta_ug',
  'vitamin_c_mg',
  'vitamin_d_ug',
  'vitamin_e_mg',
  'vitamin_k_ug',
  'thiamin_mg',
  'riboflavin_mg',
  'niacin_mg',
  'pantothenic_acid_mg',
  'vitamin_b6_mg',
  'folate_ug',
  'folate_dfe_ug',
  'vitamin_b12_ug',
  'choline_mg',
  'biotin_ug',
  'caffeine_mg',
  'theobromine_mg',
  'lycopene_ug',
  'lutein_zeaxanthin_ug',
];

/// Snapshots a catalog food's whole nutrient vector into `log_entries` in one
/// statement — the vector never becomes a Dart object.
///
/// `LEFT JOIN` because 2 of the 13,694 catalog foods have no `food_nutrition`
/// row; they log with NULL nutrients rather than failing.
///
/// Placeholders: logged_at, grams, portion_qty, portion_label, food_id.
final logCatalogFoodSql = '''
INSERT INTO log_entries (food_id, logged_at, grams, portion_qty, portion_label,
       name, emoji, ${nutrientColumns.join(', ')})
SELECT f.food_id, ?, ?, ?, ?, coalesce(f.display_name, f.description), f.emoji,
       ${nutrientColumns.map((c) => 'n.$c').join(', ')}
  FROM catalog.foods f
  LEFT JOIN catalog.food_nutrition n ON n.food_id = f.food_id
 WHERE f.food_id = ?''';

/// Same, for a custom food or a recipe — both are `custom_foods` rows.
///
/// Placeholders: logged_at, grams, portion_qty, portion_label, custom_food_id.
final logCustomFoodSql = '''
INSERT INTO log_entries (custom_food_id, logged_at, grams, portion_qty,
       portion_label, name, emoji, ${nutrientColumns.join(', ')})
SELECT c.id, ?, ?, ?, ?, c.name, c.emoji,
       ${nutrientColumns.map((c) => 'c.$c').join(', ')}
  FROM custom_foods c
 WHERE c.id = ?''';

/// Rolls a recipe's ingredients up onto its own `custom_foods` row, as a
/// grams-weighted mean back into per-100 g terms.
///
/// Ingredient nutrients come from the catalog or, for a nested custom food,
/// from that row's already-materialised columns — so this reads one level deep
/// and never recurses. A cycle (A uses B, B uses A) costs staleness, not a hang.
///
/// `serving_g` becomes the batch weight, so logging "1 recipe" means the whole
/// batch rather than falling back to the per-100 g default.
///
/// Placeholders: recipe_id (subquery), recipe_id (WHERE).
final recipeRollupSql = '''
UPDATE custom_foods
   SET serving_g = nullif(r.total_g, 0),
       ${nutrientColumns.map((c) => '$c = r.$c').join(',\n       ')}
  FROM (SELECT sum(i.grams) AS total_g,
               ${nutrientColumns.map((c) => 'sum(i.grams * coalesce(n.$c, cf.$c)) '
          '/ nullif(sum(i.grams), 0) AS $c').join(',\n               ')}
          FROM recipe_ingredients i
          LEFT JOIN catalog.food_nutrition n ON n.food_id = i.food_id
          LEFT JOIN custom_foods cf ON cf.id = i.custom_food_id
         WHERE i.recipe_id = ?) AS r
 WHERE custom_foods.id = ?''';
