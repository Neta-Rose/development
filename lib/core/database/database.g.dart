// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class CustomFoods extends Table with TableInfo<CustomFoods, CustomFood> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CustomFoods(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY DEFAULT (lower(hex(randomblob(16))))',
    defaultValue: const CustomExpression('lower(hex(randomblob(16)))'),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _barcodeMeta = const VerificationMeta(
    'barcode',
  );
  late final GeneratedColumn<String> barcode = GeneratedColumn<String>(
    'barcode',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'DEFAULT \'🍽️\'',
    defaultValue: const CustomExpression('\'🍽️\''),
  );
  static const VerificationMeta _variableFatMeta = const VerificationMeta(
    'variableFat',
  );
  late final GeneratedColumn<int> variableFat = GeneratedColumn<int>(
    'variable_fat',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _servingGMeta = const VerificationMeta(
    'servingG',
  );
  late final GeneratedColumn<double> servingG = GeneratedColumn<double>(
    'serving_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _servingLabelMeta = const VerificationMeta(
    'servingLabel',
  );
  late final GeneratedColumn<String> servingLabel = GeneratedColumn<String>(
    'serving_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (energy_kcal IS NULL OR energy_kcal >= 0)',
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (protein_g IS NULL OR protein_g >= 0)',
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (fat_g IS NULL OR fat_g >= 0)',
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (carb_g IS NULL OR carb_g >= 0)',
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (fiber_g IS NULL OR fiber_g >= 0)',
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (sugar_g IS NULL OR sugar_g >= 0)',
  );
  static const VerificationMeta _starchGMeta = const VerificationMeta(
    'starchG',
  );
  late final GeneratedColumn<double> starchG = GeneratedColumn<double>(
    'starch_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (starch_g IS NULL OR starch_g >= 0)',
  );
  static const VerificationMeta _waterGMeta = const VerificationMeta('waterG');
  late final GeneratedColumn<double> waterG = GeneratedColumn<double>(
    'water_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (water_g IS NULL OR water_g >= 0)',
  );
  static const VerificationMeta _ashGMeta = const VerificationMeta('ashG');
  late final GeneratedColumn<double> ashG = GeneratedColumn<double>(
    'ash_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (ash_g IS NULL OR ash_g >= 0)',
  );
  static const VerificationMeta _alcoholGMeta = const VerificationMeta(
    'alcoholG',
  );
  late final GeneratedColumn<double> alcoholG = GeneratedColumn<double>(
    'alcohol_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (alcohol_g IS NULL OR alcohol_g >= 0)',
  );
  static const VerificationMeta _satFatGMeta = const VerificationMeta(
    'satFatG',
  );
  late final GeneratedColumn<double> satFatG = GeneratedColumn<double>(
    'sat_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (sat_fat_g IS NULL OR sat_fat_g >= 0)',
  );
  static const VerificationMeta _monoFatGMeta = const VerificationMeta(
    'monoFatG',
  );
  late final GeneratedColumn<double> monoFatG = GeneratedColumn<double>(
    'mono_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (mono_fat_g IS NULL OR mono_fat_g >= 0)',
  );
  static const VerificationMeta _polyFatGMeta = const VerificationMeta(
    'polyFatG',
  );
  late final GeneratedColumn<double> polyFatG = GeneratedColumn<double>(
    'poly_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (poly_fat_g IS NULL OR poly_fat_g >= 0)',
  );
  static const VerificationMeta _transFatGMeta = const VerificationMeta(
    'transFatG',
  );
  late final GeneratedColumn<double> transFatG = GeneratedColumn<double>(
    'trans_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (trans_fat_g IS NULL OR trans_fat_g >= 0)',
  );
  static const VerificationMeta _cholesterolMgMeta = const VerificationMeta(
    'cholesterolMg',
  );
  late final GeneratedColumn<double> cholesterolMg = GeneratedColumn<double>(
    'cholesterol_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (cholesterol_mg IS NULL OR cholesterol_mg >= 0)',
  );
  static const VerificationMeta _omega3EpaGMeta = const VerificationMeta(
    'omega3EpaG',
  );
  late final GeneratedColumn<double> omega3EpaG = GeneratedColumn<double>(
    'omega3_epa_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (omega3_epa_g IS NULL OR omega3_epa_g >= 0)',
  );
  static const VerificationMeta _omega3DhaGMeta = const VerificationMeta(
    'omega3DhaG',
  );
  late final GeneratedColumn<double> omega3DhaG = GeneratedColumn<double>(
    'omega3_dha_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (omega3_dha_g IS NULL OR omega3_dha_g >= 0)',
  );
  static const VerificationMeta _calciumMgMeta = const VerificationMeta(
    'calciumMg',
  );
  late final GeneratedColumn<double> calciumMg = GeneratedColumn<double>(
    'calcium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (calcium_mg IS NULL OR calcium_mg >= 0)',
  );
  static const VerificationMeta _ironMgMeta = const VerificationMeta('ironMg');
  late final GeneratedColumn<double> ironMg = GeneratedColumn<double>(
    'iron_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (iron_mg IS NULL OR iron_mg >= 0)',
  );
  static const VerificationMeta _magnesiumMgMeta = const VerificationMeta(
    'magnesiumMg',
  );
  late final GeneratedColumn<double> magnesiumMg = GeneratedColumn<double>(
    'magnesium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (magnesium_mg IS NULL OR magnesium_mg >= 0)',
  );
  static const VerificationMeta _phosphorusMgMeta = const VerificationMeta(
    'phosphorusMg',
  );
  late final GeneratedColumn<double> phosphorusMg = GeneratedColumn<double>(
    'phosphorus_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (phosphorus_mg IS NULL OR phosphorus_mg >= 0)',
  );
  static const VerificationMeta _potassiumMgMeta = const VerificationMeta(
    'potassiumMg',
  );
  late final GeneratedColumn<double> potassiumMg = GeneratedColumn<double>(
    'potassium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (potassium_mg IS NULL OR potassium_mg >= 0)',
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (sodium_mg IS NULL OR sodium_mg >= 0)',
  );
  static const VerificationMeta _zincMgMeta = const VerificationMeta('zincMg');
  late final GeneratedColumn<double> zincMg = GeneratedColumn<double>(
    'zinc_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (zinc_mg IS NULL OR zinc_mg >= 0)',
  );
  static const VerificationMeta _copperMgMeta = const VerificationMeta(
    'copperMg',
  );
  late final GeneratedColumn<double> copperMg = GeneratedColumn<double>(
    'copper_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (copper_mg IS NULL OR copper_mg >= 0)',
  );
  static const VerificationMeta _manganeseMgMeta = const VerificationMeta(
    'manganeseMg',
  );
  late final GeneratedColumn<double> manganeseMg = GeneratedColumn<double>(
    'manganese_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (manganese_mg IS NULL OR manganese_mg >= 0)',
  );
  static const VerificationMeta _seleniumUgMeta = const VerificationMeta(
    'seleniumUg',
  );
  late final GeneratedColumn<double> seleniumUg = GeneratedColumn<double>(
    'selenium_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (selenium_ug IS NULL OR selenium_ug >= 0)',
  );
  static const VerificationMeta _fluorideUgMeta = const VerificationMeta(
    'fluorideUg',
  );
  late final GeneratedColumn<double> fluorideUg = GeneratedColumn<double>(
    'fluoride_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (fluoride_ug IS NULL OR fluoride_ug >= 0)',
  );
  static const VerificationMeta _iodineUgMeta = const VerificationMeta(
    'iodineUg',
  );
  late final GeneratedColumn<double> iodineUg = GeneratedColumn<double>(
    'iodine_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (iodine_ug IS NULL OR iodine_ug >= 0)',
  );
  static const VerificationMeta _vitaminARaeUgMeta = const VerificationMeta(
    'vitaminARaeUg',
  );
  late final GeneratedColumn<double> vitaminARaeUg = GeneratedColumn<double>(
    'vitamin_a_rae_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (vitamin_a_rae_ug IS NULL OR vitamin_a_rae_ug >= 0)',
  );
  static const VerificationMeta _retinolUgMeta = const VerificationMeta(
    'retinolUg',
  );
  late final GeneratedColumn<double> retinolUg = GeneratedColumn<double>(
    'retinol_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (retinol_ug IS NULL OR retinol_ug >= 0)',
  );
  static const VerificationMeta _caroteneBetaUgMeta = const VerificationMeta(
    'caroteneBetaUg',
  );
  late final GeneratedColumn<double> caroteneBetaUg = GeneratedColumn<double>(
    'carotene_beta_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints:
        'CHECK (carotene_beta_ug IS NULL OR carotene_beta_ug >= 0)',
  );
  static const VerificationMeta _vitaminCMgMeta = const VerificationMeta(
    'vitaminCMg',
  );
  late final GeneratedColumn<double> vitaminCMg = GeneratedColumn<double>(
    'vitamin_c_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (vitamin_c_mg IS NULL OR vitamin_c_mg >= 0)',
  );
  static const VerificationMeta _vitaminDUgMeta = const VerificationMeta(
    'vitaminDUg',
  );
  late final GeneratedColumn<double> vitaminDUg = GeneratedColumn<double>(
    'vitamin_d_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (vitamin_d_ug IS NULL OR vitamin_d_ug >= 0)',
  );
  static const VerificationMeta _vitaminEMgMeta = const VerificationMeta(
    'vitaminEMg',
  );
  late final GeneratedColumn<double> vitaminEMg = GeneratedColumn<double>(
    'vitamin_e_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (vitamin_e_mg IS NULL OR vitamin_e_mg >= 0)',
  );
  static const VerificationMeta _vitaminKUgMeta = const VerificationMeta(
    'vitaminKUg',
  );
  late final GeneratedColumn<double> vitaminKUg = GeneratedColumn<double>(
    'vitamin_k_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (vitamin_k_ug IS NULL OR vitamin_k_ug >= 0)',
  );
  static const VerificationMeta _thiaminMgMeta = const VerificationMeta(
    'thiaminMg',
  );
  late final GeneratedColumn<double> thiaminMg = GeneratedColumn<double>(
    'thiamin_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (thiamin_mg IS NULL OR thiamin_mg >= 0)',
  );
  static const VerificationMeta _riboflavinMgMeta = const VerificationMeta(
    'riboflavinMg',
  );
  late final GeneratedColumn<double> riboflavinMg = GeneratedColumn<double>(
    'riboflavin_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (riboflavin_mg IS NULL OR riboflavin_mg >= 0)',
  );
  static const VerificationMeta _niacinMgMeta = const VerificationMeta(
    'niacinMg',
  );
  late final GeneratedColumn<double> niacinMg = GeneratedColumn<double>(
    'niacin_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (niacin_mg IS NULL OR niacin_mg >= 0)',
  );
  static const VerificationMeta _pantothenicAcidMgMeta = const VerificationMeta(
    'pantothenicAcidMg',
  );
  late final GeneratedColumn<double> pantothenicAcidMg =
      GeneratedColumn<double>(
        'pantothenic_acid_mg',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        $customConstraints:
            'CHECK (pantothenic_acid_mg IS NULL OR pantothenic_acid_mg >= 0)',
      );
  static const VerificationMeta _vitaminB6MgMeta = const VerificationMeta(
    'vitaminB6Mg',
  );
  late final GeneratedColumn<double> vitaminB6Mg = GeneratedColumn<double>(
    'vitamin_b6_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (vitamin_b6_mg IS NULL OR vitamin_b6_mg >= 0)',
  );
  static const VerificationMeta _folateUgMeta = const VerificationMeta(
    'folateUg',
  );
  late final GeneratedColumn<double> folateUg = GeneratedColumn<double>(
    'folate_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (folate_ug IS NULL OR folate_ug >= 0)',
  );
  static const VerificationMeta _folateDfeUgMeta = const VerificationMeta(
    'folateDfeUg',
  );
  late final GeneratedColumn<double> folateDfeUg = GeneratedColumn<double>(
    'folate_dfe_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (folate_dfe_ug IS NULL OR folate_dfe_ug >= 0)',
  );
  static const VerificationMeta _vitaminB12UgMeta = const VerificationMeta(
    'vitaminB12Ug',
  );
  late final GeneratedColumn<double> vitaminB12Ug = GeneratedColumn<double>(
    'vitamin_b12_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (vitamin_b12_ug IS NULL OR vitamin_b12_ug >= 0)',
  );
  static const VerificationMeta _cholineMgMeta = const VerificationMeta(
    'cholineMg',
  );
  late final GeneratedColumn<double> cholineMg = GeneratedColumn<double>(
    'choline_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (choline_mg IS NULL OR choline_mg >= 0)',
  );
  static const VerificationMeta _biotinUgMeta = const VerificationMeta(
    'biotinUg',
  );
  late final GeneratedColumn<double> biotinUg = GeneratedColumn<double>(
    'biotin_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (biotin_ug IS NULL OR biotin_ug >= 0)',
  );
  static const VerificationMeta _caffeineMgMeta = const VerificationMeta(
    'caffeineMg',
  );
  late final GeneratedColumn<double> caffeineMg = GeneratedColumn<double>(
    'caffeine_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (caffeine_mg IS NULL OR caffeine_mg >= 0)',
  );
  static const VerificationMeta _theobromineMgMeta = const VerificationMeta(
    'theobromineMg',
  );
  late final GeneratedColumn<double> theobromineMg = GeneratedColumn<double>(
    'theobromine_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (theobromine_mg IS NULL OR theobromine_mg >= 0)',
  );
  static const VerificationMeta _lycopeneUgMeta = const VerificationMeta(
    'lycopeneUg',
  );
  late final GeneratedColumn<double> lycopeneUg = GeneratedColumn<double>(
    'lycopene_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: 'CHECK (lycopene_ug IS NULL OR lycopene_ug >= 0)',
  );
  static const VerificationMeta _luteinZeaxanthinUgMeta =
      const VerificationMeta('luteinZeaxanthinUg');
  late final GeneratedColumn<double> luteinZeaxanthinUg =
      GeneratedColumn<double>(
        'lutein_zeaxanthin_ug',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        $customConstraints:
            'CHECK (lutein_zeaxanthin_ug IS NULL OR lutein_zeaxanthin_ug >= 0)',
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT (strftime(\'%s\', \'now\'))',
    defaultValue: const CustomExpression('strftime(\'%s\', \'now\')'),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  late final GeneratedColumn<int> deleted = GeneratedColumn<int>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  late final GeneratedColumn<int> dirty = GeneratedColumn<int>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    brand,
    barcode,
    emoji,
    variableFat,
    servingG,
    servingLabel,
    energyKcal,
    proteinG,
    fatG,
    carbG,
    fiberG,
    sugarG,
    starchG,
    waterG,
    ashG,
    alcoholG,
    satFatG,
    monoFatG,
    polyFatG,
    transFatG,
    cholesterolMg,
    omega3EpaG,
    omega3DhaG,
    calciumMg,
    ironMg,
    magnesiumMg,
    phosphorusMg,
    potassiumMg,
    sodiumMg,
    zincMg,
    copperMg,
    manganeseMg,
    seleniumUg,
    fluorideUg,
    iodineUg,
    vitaminARaeUg,
    retinolUg,
    caroteneBetaUg,
    vitaminCMg,
    vitaminDUg,
    vitaminEMg,
    vitaminKUg,
    thiaminMg,
    riboflavinMg,
    niacinMg,
    pantothenicAcidMg,
    vitaminB6Mg,
    folateUg,
    folateDfeUg,
    vitaminB12Ug,
    cholineMg,
    biotinUg,
    caffeineMg,
    theobromineMg,
    lycopeneUg,
    luteinZeaxanthinUg,
    updatedAt,
    deleted,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFood> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('barcode')) {
      context.handle(
        _barcodeMeta,
        barcode.isAcceptableOrUnknown(data['barcode']!, _barcodeMeta),
      );
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('variable_fat')) {
      context.handle(
        _variableFatMeta,
        variableFat.isAcceptableOrUnknown(
          data['variable_fat']!,
          _variableFatMeta,
        ),
      );
    }
    if (data.containsKey('serving_g')) {
      context.handle(
        _servingGMeta,
        servingG.isAcceptableOrUnknown(data['serving_g']!, _servingGMeta),
      );
    }
    if (data.containsKey('serving_label')) {
      context.handle(
        _servingLabelMeta,
        servingLabel.isAcceptableOrUnknown(
          data['serving_label']!,
          _servingLabelMeta,
        ),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('starch_g')) {
      context.handle(
        _starchGMeta,
        starchG.isAcceptableOrUnknown(data['starch_g']!, _starchGMeta),
      );
    }
    if (data.containsKey('water_g')) {
      context.handle(
        _waterGMeta,
        waterG.isAcceptableOrUnknown(data['water_g']!, _waterGMeta),
      );
    }
    if (data.containsKey('ash_g')) {
      context.handle(
        _ashGMeta,
        ashG.isAcceptableOrUnknown(data['ash_g']!, _ashGMeta),
      );
    }
    if (data.containsKey('alcohol_g')) {
      context.handle(
        _alcoholGMeta,
        alcoholG.isAcceptableOrUnknown(data['alcohol_g']!, _alcoholGMeta),
      );
    }
    if (data.containsKey('sat_fat_g')) {
      context.handle(
        _satFatGMeta,
        satFatG.isAcceptableOrUnknown(data['sat_fat_g']!, _satFatGMeta),
      );
    }
    if (data.containsKey('mono_fat_g')) {
      context.handle(
        _monoFatGMeta,
        monoFatG.isAcceptableOrUnknown(data['mono_fat_g']!, _monoFatGMeta),
      );
    }
    if (data.containsKey('poly_fat_g')) {
      context.handle(
        _polyFatGMeta,
        polyFatG.isAcceptableOrUnknown(data['poly_fat_g']!, _polyFatGMeta),
      );
    }
    if (data.containsKey('trans_fat_g')) {
      context.handle(
        _transFatGMeta,
        transFatG.isAcceptableOrUnknown(data['trans_fat_g']!, _transFatGMeta),
      );
    }
    if (data.containsKey('cholesterol_mg')) {
      context.handle(
        _cholesterolMgMeta,
        cholesterolMg.isAcceptableOrUnknown(
          data['cholesterol_mg']!,
          _cholesterolMgMeta,
        ),
      );
    }
    if (data.containsKey('omega3_epa_g')) {
      context.handle(
        _omega3EpaGMeta,
        omega3EpaG.isAcceptableOrUnknown(
          data['omega3_epa_g']!,
          _omega3EpaGMeta,
        ),
      );
    }
    if (data.containsKey('omega3_dha_g')) {
      context.handle(
        _omega3DhaGMeta,
        omega3DhaG.isAcceptableOrUnknown(
          data['omega3_dha_g']!,
          _omega3DhaGMeta,
        ),
      );
    }
    if (data.containsKey('calcium_mg')) {
      context.handle(
        _calciumMgMeta,
        calciumMg.isAcceptableOrUnknown(data['calcium_mg']!, _calciumMgMeta),
      );
    }
    if (data.containsKey('iron_mg')) {
      context.handle(
        _ironMgMeta,
        ironMg.isAcceptableOrUnknown(data['iron_mg']!, _ironMgMeta),
      );
    }
    if (data.containsKey('magnesium_mg')) {
      context.handle(
        _magnesiumMgMeta,
        magnesiumMg.isAcceptableOrUnknown(
          data['magnesium_mg']!,
          _magnesiumMgMeta,
        ),
      );
    }
    if (data.containsKey('phosphorus_mg')) {
      context.handle(
        _phosphorusMgMeta,
        phosphorusMg.isAcceptableOrUnknown(
          data['phosphorus_mg']!,
          _phosphorusMgMeta,
        ),
      );
    }
    if (data.containsKey('potassium_mg')) {
      context.handle(
        _potassiumMgMeta,
        potassiumMg.isAcceptableOrUnknown(
          data['potassium_mg']!,
          _potassiumMgMeta,
        ),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('zinc_mg')) {
      context.handle(
        _zincMgMeta,
        zincMg.isAcceptableOrUnknown(data['zinc_mg']!, _zincMgMeta),
      );
    }
    if (data.containsKey('copper_mg')) {
      context.handle(
        _copperMgMeta,
        copperMg.isAcceptableOrUnknown(data['copper_mg']!, _copperMgMeta),
      );
    }
    if (data.containsKey('manganese_mg')) {
      context.handle(
        _manganeseMgMeta,
        manganeseMg.isAcceptableOrUnknown(
          data['manganese_mg']!,
          _manganeseMgMeta,
        ),
      );
    }
    if (data.containsKey('selenium_ug')) {
      context.handle(
        _seleniumUgMeta,
        seleniumUg.isAcceptableOrUnknown(data['selenium_ug']!, _seleniumUgMeta),
      );
    }
    if (data.containsKey('fluoride_ug')) {
      context.handle(
        _fluorideUgMeta,
        fluorideUg.isAcceptableOrUnknown(data['fluoride_ug']!, _fluorideUgMeta),
      );
    }
    if (data.containsKey('iodine_ug')) {
      context.handle(
        _iodineUgMeta,
        iodineUg.isAcceptableOrUnknown(data['iodine_ug']!, _iodineUgMeta),
      );
    }
    if (data.containsKey('vitamin_a_rae_ug')) {
      context.handle(
        _vitaminARaeUgMeta,
        vitaminARaeUg.isAcceptableOrUnknown(
          data['vitamin_a_rae_ug']!,
          _vitaminARaeUgMeta,
        ),
      );
    }
    if (data.containsKey('retinol_ug')) {
      context.handle(
        _retinolUgMeta,
        retinolUg.isAcceptableOrUnknown(data['retinol_ug']!, _retinolUgMeta),
      );
    }
    if (data.containsKey('carotene_beta_ug')) {
      context.handle(
        _caroteneBetaUgMeta,
        caroteneBetaUg.isAcceptableOrUnknown(
          data['carotene_beta_ug']!,
          _caroteneBetaUgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_c_mg')) {
      context.handle(
        _vitaminCMgMeta,
        vitaminCMg.isAcceptableOrUnknown(
          data['vitamin_c_mg']!,
          _vitaminCMgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_d_ug')) {
      context.handle(
        _vitaminDUgMeta,
        vitaminDUg.isAcceptableOrUnknown(
          data['vitamin_d_ug']!,
          _vitaminDUgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_e_mg')) {
      context.handle(
        _vitaminEMgMeta,
        vitaminEMg.isAcceptableOrUnknown(
          data['vitamin_e_mg']!,
          _vitaminEMgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_k_ug')) {
      context.handle(
        _vitaminKUgMeta,
        vitaminKUg.isAcceptableOrUnknown(
          data['vitamin_k_ug']!,
          _vitaminKUgMeta,
        ),
      );
    }
    if (data.containsKey('thiamin_mg')) {
      context.handle(
        _thiaminMgMeta,
        thiaminMg.isAcceptableOrUnknown(data['thiamin_mg']!, _thiaminMgMeta),
      );
    }
    if (data.containsKey('riboflavin_mg')) {
      context.handle(
        _riboflavinMgMeta,
        riboflavinMg.isAcceptableOrUnknown(
          data['riboflavin_mg']!,
          _riboflavinMgMeta,
        ),
      );
    }
    if (data.containsKey('niacin_mg')) {
      context.handle(
        _niacinMgMeta,
        niacinMg.isAcceptableOrUnknown(data['niacin_mg']!, _niacinMgMeta),
      );
    }
    if (data.containsKey('pantothenic_acid_mg')) {
      context.handle(
        _pantothenicAcidMgMeta,
        pantothenicAcidMg.isAcceptableOrUnknown(
          data['pantothenic_acid_mg']!,
          _pantothenicAcidMgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_b6_mg')) {
      context.handle(
        _vitaminB6MgMeta,
        vitaminB6Mg.isAcceptableOrUnknown(
          data['vitamin_b6_mg']!,
          _vitaminB6MgMeta,
        ),
      );
    }
    if (data.containsKey('folate_ug')) {
      context.handle(
        _folateUgMeta,
        folateUg.isAcceptableOrUnknown(data['folate_ug']!, _folateUgMeta),
      );
    }
    if (data.containsKey('folate_dfe_ug')) {
      context.handle(
        _folateDfeUgMeta,
        folateDfeUg.isAcceptableOrUnknown(
          data['folate_dfe_ug']!,
          _folateDfeUgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_b12_ug')) {
      context.handle(
        _vitaminB12UgMeta,
        vitaminB12Ug.isAcceptableOrUnknown(
          data['vitamin_b12_ug']!,
          _vitaminB12UgMeta,
        ),
      );
    }
    if (data.containsKey('choline_mg')) {
      context.handle(
        _cholineMgMeta,
        cholineMg.isAcceptableOrUnknown(data['choline_mg']!, _cholineMgMeta),
      );
    }
    if (data.containsKey('biotin_ug')) {
      context.handle(
        _biotinUgMeta,
        biotinUg.isAcceptableOrUnknown(data['biotin_ug']!, _biotinUgMeta),
      );
    }
    if (data.containsKey('caffeine_mg')) {
      context.handle(
        _caffeineMgMeta,
        caffeineMg.isAcceptableOrUnknown(data['caffeine_mg']!, _caffeineMgMeta),
      );
    }
    if (data.containsKey('theobromine_mg')) {
      context.handle(
        _theobromineMgMeta,
        theobromineMg.isAcceptableOrUnknown(
          data['theobromine_mg']!,
          _theobromineMgMeta,
        ),
      );
    }
    if (data.containsKey('lycopene_ug')) {
      context.handle(
        _lycopeneUgMeta,
        lycopeneUg.isAcceptableOrUnknown(data['lycopene_ug']!, _lycopeneUgMeta),
      );
    }
    if (data.containsKey('lutein_zeaxanthin_ug')) {
      context.handle(
        _luteinZeaxanthinUgMeta,
        luteinZeaxanthinUg.isAcceptableOrUnknown(
          data['lutein_zeaxanthin_ug']!,
          _luteinZeaxanthinUgMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CustomFood map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFood(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      barcode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}barcode'],
      ),
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      variableFat: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}variable_fat'],
      )!,
      servingG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_g'],
      ),
      servingLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_label'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      ),
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      ),
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      ),
      starchG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}starch_g'],
      ),
      waterG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_g'],
      ),
      ashG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ash_g'],
      ),
      alcoholG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alcohol_g'],
      ),
      satFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sat_fat_g'],
      ),
      monoFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mono_fat_g'],
      ),
      polyFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}poly_fat_g'],
      ),
      transFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}trans_fat_g'],
      ),
      cholesterolMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cholesterol_mg'],
      ),
      omega3EpaG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}omega3_epa_g'],
      ),
      omega3DhaG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}omega3_dha_g'],
      ),
      calciumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calcium_mg'],
      ),
      ironMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iron_mg'],
      ),
      magnesiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}magnesium_mg'],
      ),
      phosphorusMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}phosphorus_mg'],
      ),
      potassiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potassium_mg'],
      ),
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      ),
      zincMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zinc_mg'],
      ),
      copperMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}copper_mg'],
      ),
      manganeseMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}manganese_mg'],
      ),
      seleniumUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}selenium_ug'],
      ),
      fluorideUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fluoride_ug'],
      ),
      iodineUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iodine_ug'],
      ),
      vitaminARaeUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_a_rae_ug'],
      ),
      retinolUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}retinol_ug'],
      ),
      caroteneBetaUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carotene_beta_ug'],
      ),
      vitaminCMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_c_mg'],
      ),
      vitaminDUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_d_ug'],
      ),
      vitaminEMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_e_mg'],
      ),
      vitaminKUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_k_ug'],
      ),
      thiaminMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thiamin_mg'],
      ),
      riboflavinMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}riboflavin_mg'],
      ),
      niacinMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}niacin_mg'],
      ),
      pantothenicAcidMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pantothenic_acid_mg'],
      ),
      vitaminB6Mg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_b6_mg'],
      ),
      folateUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}folate_ug'],
      ),
      folateDfeUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}folate_dfe_ug'],
      ),
      vitaminB12Ug: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_b12_ug'],
      ),
      cholineMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}choline_mg'],
      ),
      biotinUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}biotin_ug'],
      ),
      caffeineMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}caffeine_mg'],
      ),
      theobromineMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}theobromine_mg'],
      ),
      lycopeneUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lycopene_ug'],
      ),
      luteinZeaxanthinUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lutein_zeaxanthin_ug'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  CustomFoods createAlias(String alias) {
    return CustomFoods(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK(length(trim(name)) > 0)',
    'CHECK(serving_g IS NULL OR serving_g > 0)',
    'CHECK(serving_label IS NULL OR serving_g IS NOT NULL)',
    'CHECK(emoji IS NULL OR(length(emoji) BETWEEN 1 AND 8 AND unicode(emoji) > 127))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CustomFood extends DataClass implements Insertable<CustomFood> {
  final String? id;
  final String name;
  final String? brand;
  final String? barcode;
  final String? emoji;
  final int variableFat;
  final double? servingG;
  final String? servingLabel;
  final double? energyKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbG;
  final double? fiberG;
  final double? sugarG;
  final double? starchG;
  final double? waterG;
  final double? ashG;
  final double? alcoholG;
  final double? satFatG;
  final double? monoFatG;
  final double? polyFatG;
  final double? transFatG;
  final double? cholesterolMg;
  final double? omega3EpaG;
  final double? omega3DhaG;
  final double? calciumMg;
  final double? ironMg;
  final double? magnesiumMg;
  final double? phosphorusMg;
  final double? potassiumMg;
  final double? sodiumMg;
  final double? zincMg;
  final double? copperMg;
  final double? manganeseMg;
  final double? seleniumUg;
  final double? fluorideUg;
  final double? iodineUg;
  final double? vitaminARaeUg;
  final double? retinolUg;
  final double? caroteneBetaUg;
  final double? vitaminCMg;
  final double? vitaminDUg;
  final double? vitaminEMg;
  final double? vitaminKUg;
  final double? thiaminMg;
  final double? riboflavinMg;
  final double? niacinMg;
  final double? pantothenicAcidMg;
  final double? vitaminB6Mg;
  final double? folateUg;
  final double? folateDfeUg;
  final double? vitaminB12Ug;
  final double? cholineMg;
  final double? biotinUg;
  final double? caffeineMg;
  final double? theobromineMg;
  final double? lycopeneUg;
  final double? luteinZeaxanthinUg;
  final int updatedAt;
  final int deleted;
  final int dirty;
  const CustomFood({
    this.id,
    required this.name,
    this.brand,
    this.barcode,
    this.emoji,
    required this.variableFat,
    this.servingG,
    this.servingLabel,
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbG,
    this.fiberG,
    this.sugarG,
    this.starchG,
    this.waterG,
    this.ashG,
    this.alcoholG,
    this.satFatG,
    this.monoFatG,
    this.polyFatG,
    this.transFatG,
    this.cholesterolMg,
    this.omega3EpaG,
    this.omega3DhaG,
    this.calciumMg,
    this.ironMg,
    this.magnesiumMg,
    this.phosphorusMg,
    this.potassiumMg,
    this.sodiumMg,
    this.zincMg,
    this.copperMg,
    this.manganeseMg,
    this.seleniumUg,
    this.fluorideUg,
    this.iodineUg,
    this.vitaminARaeUg,
    this.retinolUg,
    this.caroteneBetaUg,
    this.vitaminCMg,
    this.vitaminDUg,
    this.vitaminEMg,
    this.vitaminKUg,
    this.thiaminMg,
    this.riboflavinMg,
    this.niacinMg,
    this.pantothenicAcidMg,
    this.vitaminB6Mg,
    this.folateUg,
    this.folateDfeUg,
    this.vitaminB12Ug,
    this.cholineMg,
    this.biotinUg,
    this.caffeineMg,
    this.theobromineMg,
    this.lycopeneUg,
    this.luteinZeaxanthinUg,
    required this.updatedAt,
    required this.deleted,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || barcode != null) {
      map['barcode'] = Variable<String>(barcode);
    }
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    map['variable_fat'] = Variable<int>(variableFat);
    if (!nullToAbsent || servingG != null) {
      map['serving_g'] = Variable<double>(servingG);
    }
    if (!nullToAbsent || servingLabel != null) {
      map['serving_label'] = Variable<String>(servingLabel);
    }
    if (!nullToAbsent || energyKcal != null) {
      map['energy_kcal'] = Variable<double>(energyKcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    if (!nullToAbsent || carbG != null) {
      map['carb_g'] = Variable<double>(carbG);
    }
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    if (!nullToAbsent || sugarG != null) {
      map['sugar_g'] = Variable<double>(sugarG);
    }
    if (!nullToAbsent || starchG != null) {
      map['starch_g'] = Variable<double>(starchG);
    }
    if (!nullToAbsent || waterG != null) {
      map['water_g'] = Variable<double>(waterG);
    }
    if (!nullToAbsent || ashG != null) {
      map['ash_g'] = Variable<double>(ashG);
    }
    if (!nullToAbsent || alcoholG != null) {
      map['alcohol_g'] = Variable<double>(alcoholG);
    }
    if (!nullToAbsent || satFatG != null) {
      map['sat_fat_g'] = Variable<double>(satFatG);
    }
    if (!nullToAbsent || monoFatG != null) {
      map['mono_fat_g'] = Variable<double>(monoFatG);
    }
    if (!nullToAbsent || polyFatG != null) {
      map['poly_fat_g'] = Variable<double>(polyFatG);
    }
    if (!nullToAbsent || transFatG != null) {
      map['trans_fat_g'] = Variable<double>(transFatG);
    }
    if (!nullToAbsent || cholesterolMg != null) {
      map['cholesterol_mg'] = Variable<double>(cholesterolMg);
    }
    if (!nullToAbsent || omega3EpaG != null) {
      map['omega3_epa_g'] = Variable<double>(omega3EpaG);
    }
    if (!nullToAbsent || omega3DhaG != null) {
      map['omega3_dha_g'] = Variable<double>(omega3DhaG);
    }
    if (!nullToAbsent || calciumMg != null) {
      map['calcium_mg'] = Variable<double>(calciumMg);
    }
    if (!nullToAbsent || ironMg != null) {
      map['iron_mg'] = Variable<double>(ironMg);
    }
    if (!nullToAbsent || magnesiumMg != null) {
      map['magnesium_mg'] = Variable<double>(magnesiumMg);
    }
    if (!nullToAbsent || phosphorusMg != null) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg);
    }
    if (!nullToAbsent || potassiumMg != null) {
      map['potassium_mg'] = Variable<double>(potassiumMg);
    }
    if (!nullToAbsent || sodiumMg != null) {
      map['sodium_mg'] = Variable<double>(sodiumMg);
    }
    if (!nullToAbsent || zincMg != null) {
      map['zinc_mg'] = Variable<double>(zincMg);
    }
    if (!nullToAbsent || copperMg != null) {
      map['copper_mg'] = Variable<double>(copperMg);
    }
    if (!nullToAbsent || manganeseMg != null) {
      map['manganese_mg'] = Variable<double>(manganeseMg);
    }
    if (!nullToAbsent || seleniumUg != null) {
      map['selenium_ug'] = Variable<double>(seleniumUg);
    }
    if (!nullToAbsent || fluorideUg != null) {
      map['fluoride_ug'] = Variable<double>(fluorideUg);
    }
    if (!nullToAbsent || iodineUg != null) {
      map['iodine_ug'] = Variable<double>(iodineUg);
    }
    if (!nullToAbsent || vitaminARaeUg != null) {
      map['vitamin_a_rae_ug'] = Variable<double>(vitaminARaeUg);
    }
    if (!nullToAbsent || retinolUg != null) {
      map['retinol_ug'] = Variable<double>(retinolUg);
    }
    if (!nullToAbsent || caroteneBetaUg != null) {
      map['carotene_beta_ug'] = Variable<double>(caroteneBetaUg);
    }
    if (!nullToAbsent || vitaminCMg != null) {
      map['vitamin_c_mg'] = Variable<double>(vitaminCMg);
    }
    if (!nullToAbsent || vitaminDUg != null) {
      map['vitamin_d_ug'] = Variable<double>(vitaminDUg);
    }
    if (!nullToAbsent || vitaminEMg != null) {
      map['vitamin_e_mg'] = Variable<double>(vitaminEMg);
    }
    if (!nullToAbsent || vitaminKUg != null) {
      map['vitamin_k_ug'] = Variable<double>(vitaminKUg);
    }
    if (!nullToAbsent || thiaminMg != null) {
      map['thiamin_mg'] = Variable<double>(thiaminMg);
    }
    if (!nullToAbsent || riboflavinMg != null) {
      map['riboflavin_mg'] = Variable<double>(riboflavinMg);
    }
    if (!nullToAbsent || niacinMg != null) {
      map['niacin_mg'] = Variable<double>(niacinMg);
    }
    if (!nullToAbsent || pantothenicAcidMg != null) {
      map['pantothenic_acid_mg'] = Variable<double>(pantothenicAcidMg);
    }
    if (!nullToAbsent || vitaminB6Mg != null) {
      map['vitamin_b6_mg'] = Variable<double>(vitaminB6Mg);
    }
    if (!nullToAbsent || folateUg != null) {
      map['folate_ug'] = Variable<double>(folateUg);
    }
    if (!nullToAbsent || folateDfeUg != null) {
      map['folate_dfe_ug'] = Variable<double>(folateDfeUg);
    }
    if (!nullToAbsent || vitaminB12Ug != null) {
      map['vitamin_b12_ug'] = Variable<double>(vitaminB12Ug);
    }
    if (!nullToAbsent || cholineMg != null) {
      map['choline_mg'] = Variable<double>(cholineMg);
    }
    if (!nullToAbsent || biotinUg != null) {
      map['biotin_ug'] = Variable<double>(biotinUg);
    }
    if (!nullToAbsent || caffeineMg != null) {
      map['caffeine_mg'] = Variable<double>(caffeineMg);
    }
    if (!nullToAbsent || theobromineMg != null) {
      map['theobromine_mg'] = Variable<double>(theobromineMg);
    }
    if (!nullToAbsent || lycopeneUg != null) {
      map['lycopene_ug'] = Variable<double>(lycopeneUg);
    }
    if (!nullToAbsent || luteinZeaxanthinUg != null) {
      map['lutein_zeaxanthin_ug'] = Variable<double>(luteinZeaxanthinUg);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['deleted'] = Variable<int>(deleted);
    map['dirty'] = Variable<int>(dirty);
    return map;
  }

  CustomFoodsCompanion toCompanion(bool nullToAbsent) {
    return CustomFoodsCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      barcode: barcode == null && nullToAbsent
          ? const Value.absent()
          : Value(barcode),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      variableFat: Value(variableFat),
      servingG: servingG == null && nullToAbsent
          ? const Value.absent()
          : Value(servingG),
      servingLabel: servingLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(servingLabel),
      energyKcal: energyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(energyKcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      carbG: carbG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbG),
      fiberG: fiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG),
      sugarG: sugarG == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarG),
      starchG: starchG == null && nullToAbsent
          ? const Value.absent()
          : Value(starchG),
      waterG: waterG == null && nullToAbsent
          ? const Value.absent()
          : Value(waterG),
      ashG: ashG == null && nullToAbsent ? const Value.absent() : Value(ashG),
      alcoholG: alcoholG == null && nullToAbsent
          ? const Value.absent()
          : Value(alcoholG),
      satFatG: satFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(satFatG),
      monoFatG: monoFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(monoFatG),
      polyFatG: polyFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(polyFatG),
      transFatG: transFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(transFatG),
      cholesterolMg: cholesterolMg == null && nullToAbsent
          ? const Value.absent()
          : Value(cholesterolMg),
      omega3EpaG: omega3EpaG == null && nullToAbsent
          ? const Value.absent()
          : Value(omega3EpaG),
      omega3DhaG: omega3DhaG == null && nullToAbsent
          ? const Value.absent()
          : Value(omega3DhaG),
      calciumMg: calciumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(calciumMg),
      ironMg: ironMg == null && nullToAbsent
          ? const Value.absent()
          : Value(ironMg),
      magnesiumMg: magnesiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(magnesiumMg),
      phosphorusMg: phosphorusMg == null && nullToAbsent
          ? const Value.absent()
          : Value(phosphorusMg),
      potassiumMg: potassiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(potassiumMg),
      sodiumMg: sodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg),
      zincMg: zincMg == null && nullToAbsent
          ? const Value.absent()
          : Value(zincMg),
      copperMg: copperMg == null && nullToAbsent
          ? const Value.absent()
          : Value(copperMg),
      manganeseMg: manganeseMg == null && nullToAbsent
          ? const Value.absent()
          : Value(manganeseMg),
      seleniumUg: seleniumUg == null && nullToAbsent
          ? const Value.absent()
          : Value(seleniumUg),
      fluorideUg: fluorideUg == null && nullToAbsent
          ? const Value.absent()
          : Value(fluorideUg),
      iodineUg: iodineUg == null && nullToAbsent
          ? const Value.absent()
          : Value(iodineUg),
      vitaminARaeUg: vitaminARaeUg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminARaeUg),
      retinolUg: retinolUg == null && nullToAbsent
          ? const Value.absent()
          : Value(retinolUg),
      caroteneBetaUg: caroteneBetaUg == null && nullToAbsent
          ? const Value.absent()
          : Value(caroteneBetaUg),
      vitaminCMg: vitaminCMg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminCMg),
      vitaminDUg: vitaminDUg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminDUg),
      vitaminEMg: vitaminEMg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminEMg),
      vitaminKUg: vitaminKUg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminKUg),
      thiaminMg: thiaminMg == null && nullToAbsent
          ? const Value.absent()
          : Value(thiaminMg),
      riboflavinMg: riboflavinMg == null && nullToAbsent
          ? const Value.absent()
          : Value(riboflavinMg),
      niacinMg: niacinMg == null && nullToAbsent
          ? const Value.absent()
          : Value(niacinMg),
      pantothenicAcidMg: pantothenicAcidMg == null && nullToAbsent
          ? const Value.absent()
          : Value(pantothenicAcidMg),
      vitaminB6Mg: vitaminB6Mg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminB6Mg),
      folateUg: folateUg == null && nullToAbsent
          ? const Value.absent()
          : Value(folateUg),
      folateDfeUg: folateDfeUg == null && nullToAbsent
          ? const Value.absent()
          : Value(folateDfeUg),
      vitaminB12Ug: vitaminB12Ug == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminB12Ug),
      cholineMg: cholineMg == null && nullToAbsent
          ? const Value.absent()
          : Value(cholineMg),
      biotinUg: biotinUg == null && nullToAbsent
          ? const Value.absent()
          : Value(biotinUg),
      caffeineMg: caffeineMg == null && nullToAbsent
          ? const Value.absent()
          : Value(caffeineMg),
      theobromineMg: theobromineMg == null && nullToAbsent
          ? const Value.absent()
          : Value(theobromineMg),
      lycopeneUg: lycopeneUg == null && nullToAbsent
          ? const Value.absent()
          : Value(lycopeneUg),
      luteinZeaxanthinUg: luteinZeaxanthinUg == null && nullToAbsent
          ? const Value.absent()
          : Value(luteinZeaxanthinUg),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      dirty: Value(dirty),
    );
  }

  factory CustomFood.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFood(
      id: serializer.fromJson<String?>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      barcode: serializer.fromJson<String?>(json['barcode']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      variableFat: serializer.fromJson<int>(json['variable_fat']),
      servingG: serializer.fromJson<double?>(json['serving_g']),
      servingLabel: serializer.fromJson<String?>(json['serving_label']),
      energyKcal: serializer.fromJson<double?>(json['energy_kcal']),
      proteinG: serializer.fromJson<double?>(json['protein_g']),
      fatG: serializer.fromJson<double?>(json['fat_g']),
      carbG: serializer.fromJson<double?>(json['carb_g']),
      fiberG: serializer.fromJson<double?>(json['fiber_g']),
      sugarG: serializer.fromJson<double?>(json['sugar_g']),
      starchG: serializer.fromJson<double?>(json['starch_g']),
      waterG: serializer.fromJson<double?>(json['water_g']),
      ashG: serializer.fromJson<double?>(json['ash_g']),
      alcoholG: serializer.fromJson<double?>(json['alcohol_g']),
      satFatG: serializer.fromJson<double?>(json['sat_fat_g']),
      monoFatG: serializer.fromJson<double?>(json['mono_fat_g']),
      polyFatG: serializer.fromJson<double?>(json['poly_fat_g']),
      transFatG: serializer.fromJson<double?>(json['trans_fat_g']),
      cholesterolMg: serializer.fromJson<double?>(json['cholesterol_mg']),
      omega3EpaG: serializer.fromJson<double?>(json['omega3_epa_g']),
      omega3DhaG: serializer.fromJson<double?>(json['omega3_dha_g']),
      calciumMg: serializer.fromJson<double?>(json['calcium_mg']),
      ironMg: serializer.fromJson<double?>(json['iron_mg']),
      magnesiumMg: serializer.fromJson<double?>(json['magnesium_mg']),
      phosphorusMg: serializer.fromJson<double?>(json['phosphorus_mg']),
      potassiumMg: serializer.fromJson<double?>(json['potassium_mg']),
      sodiumMg: serializer.fromJson<double?>(json['sodium_mg']),
      zincMg: serializer.fromJson<double?>(json['zinc_mg']),
      copperMg: serializer.fromJson<double?>(json['copper_mg']),
      manganeseMg: serializer.fromJson<double?>(json['manganese_mg']),
      seleniumUg: serializer.fromJson<double?>(json['selenium_ug']),
      fluorideUg: serializer.fromJson<double?>(json['fluoride_ug']),
      iodineUg: serializer.fromJson<double?>(json['iodine_ug']),
      vitaminARaeUg: serializer.fromJson<double?>(json['vitamin_a_rae_ug']),
      retinolUg: serializer.fromJson<double?>(json['retinol_ug']),
      caroteneBetaUg: serializer.fromJson<double?>(json['carotene_beta_ug']),
      vitaminCMg: serializer.fromJson<double?>(json['vitamin_c_mg']),
      vitaminDUg: serializer.fromJson<double?>(json['vitamin_d_ug']),
      vitaminEMg: serializer.fromJson<double?>(json['vitamin_e_mg']),
      vitaminKUg: serializer.fromJson<double?>(json['vitamin_k_ug']),
      thiaminMg: serializer.fromJson<double?>(json['thiamin_mg']),
      riboflavinMg: serializer.fromJson<double?>(json['riboflavin_mg']),
      niacinMg: serializer.fromJson<double?>(json['niacin_mg']),
      pantothenicAcidMg: serializer.fromJson<double?>(
        json['pantothenic_acid_mg'],
      ),
      vitaminB6Mg: serializer.fromJson<double?>(json['vitamin_b6_mg']),
      folateUg: serializer.fromJson<double?>(json['folate_ug']),
      folateDfeUg: serializer.fromJson<double?>(json['folate_dfe_ug']),
      vitaminB12Ug: serializer.fromJson<double?>(json['vitamin_b12_ug']),
      cholineMg: serializer.fromJson<double?>(json['choline_mg']),
      biotinUg: serializer.fromJson<double?>(json['biotin_ug']),
      caffeineMg: serializer.fromJson<double?>(json['caffeine_mg']),
      theobromineMg: serializer.fromJson<double?>(json['theobromine_mg']),
      lycopeneUg: serializer.fromJson<double?>(json['lycopene_ug']),
      luteinZeaxanthinUg: serializer.fromJson<double?>(
        json['lutein_zeaxanthin_ug'],
      ),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      deleted: serializer.fromJson<int>(json['deleted']),
      dirty: serializer.fromJson<int>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'barcode': serializer.toJson<String?>(barcode),
      'emoji': serializer.toJson<String?>(emoji),
      'variable_fat': serializer.toJson<int>(variableFat),
      'serving_g': serializer.toJson<double?>(servingG),
      'serving_label': serializer.toJson<String?>(servingLabel),
      'energy_kcal': serializer.toJson<double?>(energyKcal),
      'protein_g': serializer.toJson<double?>(proteinG),
      'fat_g': serializer.toJson<double?>(fatG),
      'carb_g': serializer.toJson<double?>(carbG),
      'fiber_g': serializer.toJson<double?>(fiberG),
      'sugar_g': serializer.toJson<double?>(sugarG),
      'starch_g': serializer.toJson<double?>(starchG),
      'water_g': serializer.toJson<double?>(waterG),
      'ash_g': serializer.toJson<double?>(ashG),
      'alcohol_g': serializer.toJson<double?>(alcoholG),
      'sat_fat_g': serializer.toJson<double?>(satFatG),
      'mono_fat_g': serializer.toJson<double?>(monoFatG),
      'poly_fat_g': serializer.toJson<double?>(polyFatG),
      'trans_fat_g': serializer.toJson<double?>(transFatG),
      'cholesterol_mg': serializer.toJson<double?>(cholesterolMg),
      'omega3_epa_g': serializer.toJson<double?>(omega3EpaG),
      'omega3_dha_g': serializer.toJson<double?>(omega3DhaG),
      'calcium_mg': serializer.toJson<double?>(calciumMg),
      'iron_mg': serializer.toJson<double?>(ironMg),
      'magnesium_mg': serializer.toJson<double?>(magnesiumMg),
      'phosphorus_mg': serializer.toJson<double?>(phosphorusMg),
      'potassium_mg': serializer.toJson<double?>(potassiumMg),
      'sodium_mg': serializer.toJson<double?>(sodiumMg),
      'zinc_mg': serializer.toJson<double?>(zincMg),
      'copper_mg': serializer.toJson<double?>(copperMg),
      'manganese_mg': serializer.toJson<double?>(manganeseMg),
      'selenium_ug': serializer.toJson<double?>(seleniumUg),
      'fluoride_ug': serializer.toJson<double?>(fluorideUg),
      'iodine_ug': serializer.toJson<double?>(iodineUg),
      'vitamin_a_rae_ug': serializer.toJson<double?>(vitaminARaeUg),
      'retinol_ug': serializer.toJson<double?>(retinolUg),
      'carotene_beta_ug': serializer.toJson<double?>(caroteneBetaUg),
      'vitamin_c_mg': serializer.toJson<double?>(vitaminCMg),
      'vitamin_d_ug': serializer.toJson<double?>(vitaminDUg),
      'vitamin_e_mg': serializer.toJson<double?>(vitaminEMg),
      'vitamin_k_ug': serializer.toJson<double?>(vitaminKUg),
      'thiamin_mg': serializer.toJson<double?>(thiaminMg),
      'riboflavin_mg': serializer.toJson<double?>(riboflavinMg),
      'niacin_mg': serializer.toJson<double?>(niacinMg),
      'pantothenic_acid_mg': serializer.toJson<double?>(pantothenicAcidMg),
      'vitamin_b6_mg': serializer.toJson<double?>(vitaminB6Mg),
      'folate_ug': serializer.toJson<double?>(folateUg),
      'folate_dfe_ug': serializer.toJson<double?>(folateDfeUg),
      'vitamin_b12_ug': serializer.toJson<double?>(vitaminB12Ug),
      'choline_mg': serializer.toJson<double?>(cholineMg),
      'biotin_ug': serializer.toJson<double?>(biotinUg),
      'caffeine_mg': serializer.toJson<double?>(caffeineMg),
      'theobromine_mg': serializer.toJson<double?>(theobromineMg),
      'lycopene_ug': serializer.toJson<double?>(lycopeneUg),
      'lutein_zeaxanthin_ug': serializer.toJson<double?>(luteinZeaxanthinUg),
      'updated_at': serializer.toJson<int>(updatedAt),
      'deleted': serializer.toJson<int>(deleted),
      'dirty': serializer.toJson<int>(dirty),
    };
  }

  CustomFood copyWith({
    Value<String?> id = const Value.absent(),
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<String?> barcode = const Value.absent(),
    Value<String?> emoji = const Value.absent(),
    int? variableFat,
    Value<double?> servingG = const Value.absent(),
    Value<String?> servingLabel = const Value.absent(),
    Value<double?> energyKcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    Value<double?> carbG = const Value.absent(),
    Value<double?> fiberG = const Value.absent(),
    Value<double?> sugarG = const Value.absent(),
    Value<double?> starchG = const Value.absent(),
    Value<double?> waterG = const Value.absent(),
    Value<double?> ashG = const Value.absent(),
    Value<double?> alcoholG = const Value.absent(),
    Value<double?> satFatG = const Value.absent(),
    Value<double?> monoFatG = const Value.absent(),
    Value<double?> polyFatG = const Value.absent(),
    Value<double?> transFatG = const Value.absent(),
    Value<double?> cholesterolMg = const Value.absent(),
    Value<double?> omega3EpaG = const Value.absent(),
    Value<double?> omega3DhaG = const Value.absent(),
    Value<double?> calciumMg = const Value.absent(),
    Value<double?> ironMg = const Value.absent(),
    Value<double?> magnesiumMg = const Value.absent(),
    Value<double?> phosphorusMg = const Value.absent(),
    Value<double?> potassiumMg = const Value.absent(),
    Value<double?> sodiumMg = const Value.absent(),
    Value<double?> zincMg = const Value.absent(),
    Value<double?> copperMg = const Value.absent(),
    Value<double?> manganeseMg = const Value.absent(),
    Value<double?> seleniumUg = const Value.absent(),
    Value<double?> fluorideUg = const Value.absent(),
    Value<double?> iodineUg = const Value.absent(),
    Value<double?> vitaminARaeUg = const Value.absent(),
    Value<double?> retinolUg = const Value.absent(),
    Value<double?> caroteneBetaUg = const Value.absent(),
    Value<double?> vitaminCMg = const Value.absent(),
    Value<double?> vitaminDUg = const Value.absent(),
    Value<double?> vitaminEMg = const Value.absent(),
    Value<double?> vitaminKUg = const Value.absent(),
    Value<double?> thiaminMg = const Value.absent(),
    Value<double?> riboflavinMg = const Value.absent(),
    Value<double?> niacinMg = const Value.absent(),
    Value<double?> pantothenicAcidMg = const Value.absent(),
    Value<double?> vitaminB6Mg = const Value.absent(),
    Value<double?> folateUg = const Value.absent(),
    Value<double?> folateDfeUg = const Value.absent(),
    Value<double?> vitaminB12Ug = const Value.absent(),
    Value<double?> cholineMg = const Value.absent(),
    Value<double?> biotinUg = const Value.absent(),
    Value<double?> caffeineMg = const Value.absent(),
    Value<double?> theobromineMg = const Value.absent(),
    Value<double?> lycopeneUg = const Value.absent(),
    Value<double?> luteinZeaxanthinUg = const Value.absent(),
    int? updatedAt,
    int? deleted,
    int? dirty,
  }) => CustomFood(
    id: id.present ? id.value : this.id,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    barcode: barcode.present ? barcode.value : this.barcode,
    emoji: emoji.present ? emoji.value : this.emoji,
    variableFat: variableFat ?? this.variableFat,
    servingG: servingG.present ? servingG.value : this.servingG,
    servingLabel: servingLabel.present ? servingLabel.value : this.servingLabel,
    energyKcal: energyKcal.present ? energyKcal.value : this.energyKcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    fatG: fatG.present ? fatG.value : this.fatG,
    carbG: carbG.present ? carbG.value : this.carbG,
    fiberG: fiberG.present ? fiberG.value : this.fiberG,
    sugarG: sugarG.present ? sugarG.value : this.sugarG,
    starchG: starchG.present ? starchG.value : this.starchG,
    waterG: waterG.present ? waterG.value : this.waterG,
    ashG: ashG.present ? ashG.value : this.ashG,
    alcoholG: alcoholG.present ? alcoholG.value : this.alcoholG,
    satFatG: satFatG.present ? satFatG.value : this.satFatG,
    monoFatG: monoFatG.present ? monoFatG.value : this.monoFatG,
    polyFatG: polyFatG.present ? polyFatG.value : this.polyFatG,
    transFatG: transFatG.present ? transFatG.value : this.transFatG,
    cholesterolMg: cholesterolMg.present
        ? cholesterolMg.value
        : this.cholesterolMg,
    omega3EpaG: omega3EpaG.present ? omega3EpaG.value : this.omega3EpaG,
    omega3DhaG: omega3DhaG.present ? omega3DhaG.value : this.omega3DhaG,
    calciumMg: calciumMg.present ? calciumMg.value : this.calciumMg,
    ironMg: ironMg.present ? ironMg.value : this.ironMg,
    magnesiumMg: magnesiumMg.present ? magnesiumMg.value : this.magnesiumMg,
    phosphorusMg: phosphorusMg.present ? phosphorusMg.value : this.phosphorusMg,
    potassiumMg: potassiumMg.present ? potassiumMg.value : this.potassiumMg,
    sodiumMg: sodiumMg.present ? sodiumMg.value : this.sodiumMg,
    zincMg: zincMg.present ? zincMg.value : this.zincMg,
    copperMg: copperMg.present ? copperMg.value : this.copperMg,
    manganeseMg: manganeseMg.present ? manganeseMg.value : this.manganeseMg,
    seleniumUg: seleniumUg.present ? seleniumUg.value : this.seleniumUg,
    fluorideUg: fluorideUg.present ? fluorideUg.value : this.fluorideUg,
    iodineUg: iodineUg.present ? iodineUg.value : this.iodineUg,
    vitaminARaeUg: vitaminARaeUg.present
        ? vitaminARaeUg.value
        : this.vitaminARaeUg,
    retinolUg: retinolUg.present ? retinolUg.value : this.retinolUg,
    caroteneBetaUg: caroteneBetaUg.present
        ? caroteneBetaUg.value
        : this.caroteneBetaUg,
    vitaminCMg: vitaminCMg.present ? vitaminCMg.value : this.vitaminCMg,
    vitaminDUg: vitaminDUg.present ? vitaminDUg.value : this.vitaminDUg,
    vitaminEMg: vitaminEMg.present ? vitaminEMg.value : this.vitaminEMg,
    vitaminKUg: vitaminKUg.present ? vitaminKUg.value : this.vitaminKUg,
    thiaminMg: thiaminMg.present ? thiaminMg.value : this.thiaminMg,
    riboflavinMg: riboflavinMg.present ? riboflavinMg.value : this.riboflavinMg,
    niacinMg: niacinMg.present ? niacinMg.value : this.niacinMg,
    pantothenicAcidMg: pantothenicAcidMg.present
        ? pantothenicAcidMg.value
        : this.pantothenicAcidMg,
    vitaminB6Mg: vitaminB6Mg.present ? vitaminB6Mg.value : this.vitaminB6Mg,
    folateUg: folateUg.present ? folateUg.value : this.folateUg,
    folateDfeUg: folateDfeUg.present ? folateDfeUg.value : this.folateDfeUg,
    vitaminB12Ug: vitaminB12Ug.present ? vitaminB12Ug.value : this.vitaminB12Ug,
    cholineMg: cholineMg.present ? cholineMg.value : this.cholineMg,
    biotinUg: biotinUg.present ? biotinUg.value : this.biotinUg,
    caffeineMg: caffeineMg.present ? caffeineMg.value : this.caffeineMg,
    theobromineMg: theobromineMg.present
        ? theobromineMg.value
        : this.theobromineMg,
    lycopeneUg: lycopeneUg.present ? lycopeneUg.value : this.lycopeneUg,
    luteinZeaxanthinUg: luteinZeaxanthinUg.present
        ? luteinZeaxanthinUg.value
        : this.luteinZeaxanthinUg,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    dirty: dirty ?? this.dirty,
  );
  CustomFood copyWithCompanion(CustomFoodsCompanion data) {
    return CustomFood(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      barcode: data.barcode.present ? data.barcode.value : this.barcode,
      emoji: data.emoji.present ? data.emoji.value : this.emoji,
      variableFat: data.variableFat.present
          ? data.variableFat.value
          : this.variableFat,
      servingG: data.servingG.present ? data.servingG.value : this.servingG,
      servingLabel: data.servingLabel.present
          ? data.servingLabel.value
          : this.servingLabel,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      carbG: data.carbG.present ? data.carbG.value : this.carbG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      starchG: data.starchG.present ? data.starchG.value : this.starchG,
      waterG: data.waterG.present ? data.waterG.value : this.waterG,
      ashG: data.ashG.present ? data.ashG.value : this.ashG,
      alcoholG: data.alcoholG.present ? data.alcoholG.value : this.alcoholG,
      satFatG: data.satFatG.present ? data.satFatG.value : this.satFatG,
      monoFatG: data.monoFatG.present ? data.monoFatG.value : this.monoFatG,
      polyFatG: data.polyFatG.present ? data.polyFatG.value : this.polyFatG,
      transFatG: data.transFatG.present ? data.transFatG.value : this.transFatG,
      cholesterolMg: data.cholesterolMg.present
          ? data.cholesterolMg.value
          : this.cholesterolMg,
      omega3EpaG: data.omega3EpaG.present
          ? data.omega3EpaG.value
          : this.omega3EpaG,
      omega3DhaG: data.omega3DhaG.present
          ? data.omega3DhaG.value
          : this.omega3DhaG,
      calciumMg: data.calciumMg.present ? data.calciumMg.value : this.calciumMg,
      ironMg: data.ironMg.present ? data.ironMg.value : this.ironMg,
      magnesiumMg: data.magnesiumMg.present
          ? data.magnesiumMg.value
          : this.magnesiumMg,
      phosphorusMg: data.phosphorusMg.present
          ? data.phosphorusMg.value
          : this.phosphorusMg,
      potassiumMg: data.potassiumMg.present
          ? data.potassiumMg.value
          : this.potassiumMg,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      zincMg: data.zincMg.present ? data.zincMg.value : this.zincMg,
      copperMg: data.copperMg.present ? data.copperMg.value : this.copperMg,
      manganeseMg: data.manganeseMg.present
          ? data.manganeseMg.value
          : this.manganeseMg,
      seleniumUg: data.seleniumUg.present
          ? data.seleniumUg.value
          : this.seleniumUg,
      fluorideUg: data.fluorideUg.present
          ? data.fluorideUg.value
          : this.fluorideUg,
      iodineUg: data.iodineUg.present ? data.iodineUg.value : this.iodineUg,
      vitaminARaeUg: data.vitaminARaeUg.present
          ? data.vitaminARaeUg.value
          : this.vitaminARaeUg,
      retinolUg: data.retinolUg.present ? data.retinolUg.value : this.retinolUg,
      caroteneBetaUg: data.caroteneBetaUg.present
          ? data.caroteneBetaUg.value
          : this.caroteneBetaUg,
      vitaminCMg: data.vitaminCMg.present
          ? data.vitaminCMg.value
          : this.vitaminCMg,
      vitaminDUg: data.vitaminDUg.present
          ? data.vitaminDUg.value
          : this.vitaminDUg,
      vitaminEMg: data.vitaminEMg.present
          ? data.vitaminEMg.value
          : this.vitaminEMg,
      vitaminKUg: data.vitaminKUg.present
          ? data.vitaminKUg.value
          : this.vitaminKUg,
      thiaminMg: data.thiaminMg.present ? data.thiaminMg.value : this.thiaminMg,
      riboflavinMg: data.riboflavinMg.present
          ? data.riboflavinMg.value
          : this.riboflavinMg,
      niacinMg: data.niacinMg.present ? data.niacinMg.value : this.niacinMg,
      pantothenicAcidMg: data.pantothenicAcidMg.present
          ? data.pantothenicAcidMg.value
          : this.pantothenicAcidMg,
      vitaminB6Mg: data.vitaminB6Mg.present
          ? data.vitaminB6Mg.value
          : this.vitaminB6Mg,
      folateUg: data.folateUg.present ? data.folateUg.value : this.folateUg,
      folateDfeUg: data.folateDfeUg.present
          ? data.folateDfeUg.value
          : this.folateDfeUg,
      vitaminB12Ug: data.vitaminB12Ug.present
          ? data.vitaminB12Ug.value
          : this.vitaminB12Ug,
      cholineMg: data.cholineMg.present ? data.cholineMg.value : this.cholineMg,
      biotinUg: data.biotinUg.present ? data.biotinUg.value : this.biotinUg,
      caffeineMg: data.caffeineMg.present
          ? data.caffeineMg.value
          : this.caffeineMg,
      theobromineMg: data.theobromineMg.present
          ? data.theobromineMg.value
          : this.theobromineMg,
      lycopeneUg: data.lycopeneUg.present
          ? data.lycopeneUg.value
          : this.lycopeneUg,
      luteinZeaxanthinUg: data.luteinZeaxanthinUg.present
          ? data.luteinZeaxanthinUg.value
          : this.luteinZeaxanthinUg,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deleted: data.deleted.present ? data.deleted.value : this.deleted,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFood(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('emoji: $emoji, ')
          ..write('variableFat: $variableFat, ')
          ..write('servingG: $servingG, ')
          ..write('servingLabel: $servingLabel, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('starchG: $starchG, ')
          ..write('waterG: $waterG, ')
          ..write('ashG: $ashG, ')
          ..write('alcoholG: $alcoholG, ')
          ..write('satFatG: $satFatG, ')
          ..write('monoFatG: $monoFatG, ')
          ..write('polyFatG: $polyFatG, ')
          ..write('transFatG: $transFatG, ')
          ..write('cholesterolMg: $cholesterolMg, ')
          ..write('omega3EpaG: $omega3EpaG, ')
          ..write('omega3DhaG: $omega3DhaG, ')
          ..write('calciumMg: $calciumMg, ')
          ..write('ironMg: $ironMg, ')
          ..write('magnesiumMg: $magnesiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('zincMg: $zincMg, ')
          ..write('copperMg: $copperMg, ')
          ..write('manganeseMg: $manganeseMg, ')
          ..write('seleniumUg: $seleniumUg, ')
          ..write('fluorideUg: $fluorideUg, ')
          ..write('iodineUg: $iodineUg, ')
          ..write('vitaminARaeUg: $vitaminARaeUg, ')
          ..write('retinolUg: $retinolUg, ')
          ..write('caroteneBetaUg: $caroteneBetaUg, ')
          ..write('vitaminCMg: $vitaminCMg, ')
          ..write('vitaminDUg: $vitaminDUg, ')
          ..write('vitaminEMg: $vitaminEMg, ')
          ..write('vitaminKUg: $vitaminKUg, ')
          ..write('thiaminMg: $thiaminMg, ')
          ..write('riboflavinMg: $riboflavinMg, ')
          ..write('niacinMg: $niacinMg, ')
          ..write('pantothenicAcidMg: $pantothenicAcidMg, ')
          ..write('vitaminB6Mg: $vitaminB6Mg, ')
          ..write('folateUg: $folateUg, ')
          ..write('folateDfeUg: $folateDfeUg, ')
          ..write('vitaminB12Ug: $vitaminB12Ug, ')
          ..write('cholineMg: $cholineMg, ')
          ..write('biotinUg: $biotinUg, ')
          ..write('caffeineMg: $caffeineMg, ')
          ..write('theobromineMg: $theobromineMg, ')
          ..write('lycopeneUg: $lycopeneUg, ')
          ..write('luteinZeaxanthinUg: $luteinZeaxanthinUg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    name,
    brand,
    barcode,
    emoji,
    variableFat,
    servingG,
    servingLabel,
    energyKcal,
    proteinG,
    fatG,
    carbG,
    fiberG,
    sugarG,
    starchG,
    waterG,
    ashG,
    alcoholG,
    satFatG,
    monoFatG,
    polyFatG,
    transFatG,
    cholesterolMg,
    omega3EpaG,
    omega3DhaG,
    calciumMg,
    ironMg,
    magnesiumMg,
    phosphorusMg,
    potassiumMg,
    sodiumMg,
    zincMg,
    copperMg,
    manganeseMg,
    seleniumUg,
    fluorideUg,
    iodineUg,
    vitaminARaeUg,
    retinolUg,
    caroteneBetaUg,
    vitaminCMg,
    vitaminDUg,
    vitaminEMg,
    vitaminKUg,
    thiaminMg,
    riboflavinMg,
    niacinMg,
    pantothenicAcidMg,
    vitaminB6Mg,
    folateUg,
    folateDfeUg,
    vitaminB12Ug,
    cholineMg,
    biotinUg,
    caffeineMg,
    theobromineMg,
    lycopeneUg,
    luteinZeaxanthinUg,
    updatedAt,
    deleted,
    dirty,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFood &&
          other.id == this.id &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.barcode == this.barcode &&
          other.emoji == this.emoji &&
          other.variableFat == this.variableFat &&
          other.servingG == this.servingG &&
          other.servingLabel == this.servingLabel &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.fatG == this.fatG &&
          other.carbG == this.carbG &&
          other.fiberG == this.fiberG &&
          other.sugarG == this.sugarG &&
          other.starchG == this.starchG &&
          other.waterG == this.waterG &&
          other.ashG == this.ashG &&
          other.alcoholG == this.alcoholG &&
          other.satFatG == this.satFatG &&
          other.monoFatG == this.monoFatG &&
          other.polyFatG == this.polyFatG &&
          other.transFatG == this.transFatG &&
          other.cholesterolMg == this.cholesterolMg &&
          other.omega3EpaG == this.omega3EpaG &&
          other.omega3DhaG == this.omega3DhaG &&
          other.calciumMg == this.calciumMg &&
          other.ironMg == this.ironMg &&
          other.magnesiumMg == this.magnesiumMg &&
          other.phosphorusMg == this.phosphorusMg &&
          other.potassiumMg == this.potassiumMg &&
          other.sodiumMg == this.sodiumMg &&
          other.zincMg == this.zincMg &&
          other.copperMg == this.copperMg &&
          other.manganeseMg == this.manganeseMg &&
          other.seleniumUg == this.seleniumUg &&
          other.fluorideUg == this.fluorideUg &&
          other.iodineUg == this.iodineUg &&
          other.vitaminARaeUg == this.vitaminARaeUg &&
          other.retinolUg == this.retinolUg &&
          other.caroteneBetaUg == this.caroteneBetaUg &&
          other.vitaminCMg == this.vitaminCMg &&
          other.vitaminDUg == this.vitaminDUg &&
          other.vitaminEMg == this.vitaminEMg &&
          other.vitaminKUg == this.vitaminKUg &&
          other.thiaminMg == this.thiaminMg &&
          other.riboflavinMg == this.riboflavinMg &&
          other.niacinMg == this.niacinMg &&
          other.pantothenicAcidMg == this.pantothenicAcidMg &&
          other.vitaminB6Mg == this.vitaminB6Mg &&
          other.folateUg == this.folateUg &&
          other.folateDfeUg == this.folateDfeUg &&
          other.vitaminB12Ug == this.vitaminB12Ug &&
          other.cholineMg == this.cholineMg &&
          other.biotinUg == this.biotinUg &&
          other.caffeineMg == this.caffeineMg &&
          other.theobromineMg == this.theobromineMg &&
          other.lycopeneUg == this.lycopeneUg &&
          other.luteinZeaxanthinUg == this.luteinZeaxanthinUg &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.dirty == this.dirty);
}

class CustomFoodsCompanion extends UpdateCompanion<CustomFood> {
  final Value<String?> id;
  final Value<String> name;
  final Value<String?> brand;
  final Value<String?> barcode;
  final Value<String?> emoji;
  final Value<int> variableFat;
  final Value<double?> servingG;
  final Value<String?> servingLabel;
  final Value<double?> energyKcal;
  final Value<double?> proteinG;
  final Value<double?> fatG;
  final Value<double?> carbG;
  final Value<double?> fiberG;
  final Value<double?> sugarG;
  final Value<double?> starchG;
  final Value<double?> waterG;
  final Value<double?> ashG;
  final Value<double?> alcoholG;
  final Value<double?> satFatG;
  final Value<double?> monoFatG;
  final Value<double?> polyFatG;
  final Value<double?> transFatG;
  final Value<double?> cholesterolMg;
  final Value<double?> omega3EpaG;
  final Value<double?> omega3DhaG;
  final Value<double?> calciumMg;
  final Value<double?> ironMg;
  final Value<double?> magnesiumMg;
  final Value<double?> phosphorusMg;
  final Value<double?> potassiumMg;
  final Value<double?> sodiumMg;
  final Value<double?> zincMg;
  final Value<double?> copperMg;
  final Value<double?> manganeseMg;
  final Value<double?> seleniumUg;
  final Value<double?> fluorideUg;
  final Value<double?> iodineUg;
  final Value<double?> vitaminARaeUg;
  final Value<double?> retinolUg;
  final Value<double?> caroteneBetaUg;
  final Value<double?> vitaminCMg;
  final Value<double?> vitaminDUg;
  final Value<double?> vitaminEMg;
  final Value<double?> vitaminKUg;
  final Value<double?> thiaminMg;
  final Value<double?> riboflavinMg;
  final Value<double?> niacinMg;
  final Value<double?> pantothenicAcidMg;
  final Value<double?> vitaminB6Mg;
  final Value<double?> folateUg;
  final Value<double?> folateDfeUg;
  final Value<double?> vitaminB12Ug;
  final Value<double?> cholineMg;
  final Value<double?> biotinUg;
  final Value<double?> caffeineMg;
  final Value<double?> theobromineMg;
  final Value<double?> lycopeneUg;
  final Value<double?> luteinZeaxanthinUg;
  final Value<int> updatedAt;
  final Value<int> deleted;
  final Value<int> dirty;
  final Value<int> rowid;
  const CustomFoodsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.emoji = const Value.absent(),
    this.variableFat = const Value.absent(),
    this.servingG = const Value.absent(),
    this.servingLabel = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.starchG = const Value.absent(),
    this.waterG = const Value.absent(),
    this.ashG = const Value.absent(),
    this.alcoholG = const Value.absent(),
    this.satFatG = const Value.absent(),
    this.monoFatG = const Value.absent(),
    this.polyFatG = const Value.absent(),
    this.transFatG = const Value.absent(),
    this.cholesterolMg = const Value.absent(),
    this.omega3EpaG = const Value.absent(),
    this.omega3DhaG = const Value.absent(),
    this.calciumMg = const Value.absent(),
    this.ironMg = const Value.absent(),
    this.magnesiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.zincMg = const Value.absent(),
    this.copperMg = const Value.absent(),
    this.manganeseMg = const Value.absent(),
    this.seleniumUg = const Value.absent(),
    this.fluorideUg = const Value.absent(),
    this.iodineUg = const Value.absent(),
    this.vitaminARaeUg = const Value.absent(),
    this.retinolUg = const Value.absent(),
    this.caroteneBetaUg = const Value.absent(),
    this.vitaminCMg = const Value.absent(),
    this.vitaminDUg = const Value.absent(),
    this.vitaminEMg = const Value.absent(),
    this.vitaminKUg = const Value.absent(),
    this.thiaminMg = const Value.absent(),
    this.riboflavinMg = const Value.absent(),
    this.niacinMg = const Value.absent(),
    this.pantothenicAcidMg = const Value.absent(),
    this.vitaminB6Mg = const Value.absent(),
    this.folateUg = const Value.absent(),
    this.folateDfeUg = const Value.absent(),
    this.vitaminB12Ug = const Value.absent(),
    this.cholineMg = const Value.absent(),
    this.biotinUg = const Value.absent(),
    this.caffeineMg = const Value.absent(),
    this.theobromineMg = const Value.absent(),
    this.lycopeneUg = const Value.absent(),
    this.luteinZeaxanthinUg = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CustomFoodsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.barcode = const Value.absent(),
    this.emoji = const Value.absent(),
    this.variableFat = const Value.absent(),
    this.servingG = const Value.absent(),
    this.servingLabel = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.starchG = const Value.absent(),
    this.waterG = const Value.absent(),
    this.ashG = const Value.absent(),
    this.alcoholG = const Value.absent(),
    this.satFatG = const Value.absent(),
    this.monoFatG = const Value.absent(),
    this.polyFatG = const Value.absent(),
    this.transFatG = const Value.absent(),
    this.cholesterolMg = const Value.absent(),
    this.omega3EpaG = const Value.absent(),
    this.omega3DhaG = const Value.absent(),
    this.calciumMg = const Value.absent(),
    this.ironMg = const Value.absent(),
    this.magnesiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.zincMg = const Value.absent(),
    this.copperMg = const Value.absent(),
    this.manganeseMg = const Value.absent(),
    this.seleniumUg = const Value.absent(),
    this.fluorideUg = const Value.absent(),
    this.iodineUg = const Value.absent(),
    this.vitaminARaeUg = const Value.absent(),
    this.retinolUg = const Value.absent(),
    this.caroteneBetaUg = const Value.absent(),
    this.vitaminCMg = const Value.absent(),
    this.vitaminDUg = const Value.absent(),
    this.vitaminEMg = const Value.absent(),
    this.vitaminKUg = const Value.absent(),
    this.thiaminMg = const Value.absent(),
    this.riboflavinMg = const Value.absent(),
    this.niacinMg = const Value.absent(),
    this.pantothenicAcidMg = const Value.absent(),
    this.vitaminB6Mg = const Value.absent(),
    this.folateUg = const Value.absent(),
    this.folateDfeUg = const Value.absent(),
    this.vitaminB12Ug = const Value.absent(),
    this.cholineMg = const Value.absent(),
    this.biotinUg = const Value.absent(),
    this.caffeineMg = const Value.absent(),
    this.theobromineMg = const Value.absent(),
    this.lycopeneUg = const Value.absent(),
    this.luteinZeaxanthinUg = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : name = Value(name);
  static Insertable<CustomFood> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<String>? barcode,
    Expression<String>? emoji,
    Expression<int>? variableFat,
    Expression<double>? servingG,
    Expression<String>? servingLabel,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? fatG,
    Expression<double>? carbG,
    Expression<double>? fiberG,
    Expression<double>? sugarG,
    Expression<double>? starchG,
    Expression<double>? waterG,
    Expression<double>? ashG,
    Expression<double>? alcoholG,
    Expression<double>? satFatG,
    Expression<double>? monoFatG,
    Expression<double>? polyFatG,
    Expression<double>? transFatG,
    Expression<double>? cholesterolMg,
    Expression<double>? omega3EpaG,
    Expression<double>? omega3DhaG,
    Expression<double>? calciumMg,
    Expression<double>? ironMg,
    Expression<double>? magnesiumMg,
    Expression<double>? phosphorusMg,
    Expression<double>? potassiumMg,
    Expression<double>? sodiumMg,
    Expression<double>? zincMg,
    Expression<double>? copperMg,
    Expression<double>? manganeseMg,
    Expression<double>? seleniumUg,
    Expression<double>? fluorideUg,
    Expression<double>? iodineUg,
    Expression<double>? vitaminARaeUg,
    Expression<double>? retinolUg,
    Expression<double>? caroteneBetaUg,
    Expression<double>? vitaminCMg,
    Expression<double>? vitaminDUg,
    Expression<double>? vitaminEMg,
    Expression<double>? vitaminKUg,
    Expression<double>? thiaminMg,
    Expression<double>? riboflavinMg,
    Expression<double>? niacinMg,
    Expression<double>? pantothenicAcidMg,
    Expression<double>? vitaminB6Mg,
    Expression<double>? folateUg,
    Expression<double>? folateDfeUg,
    Expression<double>? vitaminB12Ug,
    Expression<double>? cholineMg,
    Expression<double>? biotinUg,
    Expression<double>? caffeineMg,
    Expression<double>? theobromineMg,
    Expression<double>? lycopeneUg,
    Expression<double>? luteinZeaxanthinUg,
    Expression<int>? updatedAt,
    Expression<int>? deleted,
    Expression<int>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (barcode != null) 'barcode': barcode,
      if (emoji != null) 'emoji': emoji,
      if (variableFat != null) 'variable_fat': variableFat,
      if (servingG != null) 'serving_g': servingG,
      if (servingLabel != null) 'serving_label': servingLabel,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbG != null) 'carb_g': carbG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (starchG != null) 'starch_g': starchG,
      if (waterG != null) 'water_g': waterG,
      if (ashG != null) 'ash_g': ashG,
      if (alcoholG != null) 'alcohol_g': alcoholG,
      if (satFatG != null) 'sat_fat_g': satFatG,
      if (monoFatG != null) 'mono_fat_g': monoFatG,
      if (polyFatG != null) 'poly_fat_g': polyFatG,
      if (transFatG != null) 'trans_fat_g': transFatG,
      if (cholesterolMg != null) 'cholesterol_mg': cholesterolMg,
      if (omega3EpaG != null) 'omega3_epa_g': omega3EpaG,
      if (omega3DhaG != null) 'omega3_dha_g': omega3DhaG,
      if (calciumMg != null) 'calcium_mg': calciumMg,
      if (ironMg != null) 'iron_mg': ironMg,
      if (magnesiumMg != null) 'magnesium_mg': magnesiumMg,
      if (phosphorusMg != null) 'phosphorus_mg': phosphorusMg,
      if (potassiumMg != null) 'potassium_mg': potassiumMg,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (zincMg != null) 'zinc_mg': zincMg,
      if (copperMg != null) 'copper_mg': copperMg,
      if (manganeseMg != null) 'manganese_mg': manganeseMg,
      if (seleniumUg != null) 'selenium_ug': seleniumUg,
      if (fluorideUg != null) 'fluoride_ug': fluorideUg,
      if (iodineUg != null) 'iodine_ug': iodineUg,
      if (vitaminARaeUg != null) 'vitamin_a_rae_ug': vitaminARaeUg,
      if (retinolUg != null) 'retinol_ug': retinolUg,
      if (caroteneBetaUg != null) 'carotene_beta_ug': caroteneBetaUg,
      if (vitaminCMg != null) 'vitamin_c_mg': vitaminCMg,
      if (vitaminDUg != null) 'vitamin_d_ug': vitaminDUg,
      if (vitaminEMg != null) 'vitamin_e_mg': vitaminEMg,
      if (vitaminKUg != null) 'vitamin_k_ug': vitaminKUg,
      if (thiaminMg != null) 'thiamin_mg': thiaminMg,
      if (riboflavinMg != null) 'riboflavin_mg': riboflavinMg,
      if (niacinMg != null) 'niacin_mg': niacinMg,
      if (pantothenicAcidMg != null) 'pantothenic_acid_mg': pantothenicAcidMg,
      if (vitaminB6Mg != null) 'vitamin_b6_mg': vitaminB6Mg,
      if (folateUg != null) 'folate_ug': folateUg,
      if (folateDfeUg != null) 'folate_dfe_ug': folateDfeUg,
      if (vitaminB12Ug != null) 'vitamin_b12_ug': vitaminB12Ug,
      if (cholineMg != null) 'choline_mg': cholineMg,
      if (biotinUg != null) 'biotin_ug': biotinUg,
      if (caffeineMg != null) 'caffeine_mg': caffeineMg,
      if (theobromineMg != null) 'theobromine_mg': theobromineMg,
      if (lycopeneUg != null) 'lycopene_ug': lycopeneUg,
      if (luteinZeaxanthinUg != null)
        'lutein_zeaxanthin_ug': luteinZeaxanthinUg,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CustomFoodsCompanion copyWith({
    Value<String?>? id,
    Value<String>? name,
    Value<String?>? brand,
    Value<String?>? barcode,
    Value<String?>? emoji,
    Value<int>? variableFat,
    Value<double?>? servingG,
    Value<String?>? servingLabel,
    Value<double?>? energyKcal,
    Value<double?>? proteinG,
    Value<double?>? fatG,
    Value<double?>? carbG,
    Value<double?>? fiberG,
    Value<double?>? sugarG,
    Value<double?>? starchG,
    Value<double?>? waterG,
    Value<double?>? ashG,
    Value<double?>? alcoholG,
    Value<double?>? satFatG,
    Value<double?>? monoFatG,
    Value<double?>? polyFatG,
    Value<double?>? transFatG,
    Value<double?>? cholesterolMg,
    Value<double?>? omega3EpaG,
    Value<double?>? omega3DhaG,
    Value<double?>? calciumMg,
    Value<double?>? ironMg,
    Value<double?>? magnesiumMg,
    Value<double?>? phosphorusMg,
    Value<double?>? potassiumMg,
    Value<double?>? sodiumMg,
    Value<double?>? zincMg,
    Value<double?>? copperMg,
    Value<double?>? manganeseMg,
    Value<double?>? seleniumUg,
    Value<double?>? fluorideUg,
    Value<double?>? iodineUg,
    Value<double?>? vitaminARaeUg,
    Value<double?>? retinolUg,
    Value<double?>? caroteneBetaUg,
    Value<double?>? vitaminCMg,
    Value<double?>? vitaminDUg,
    Value<double?>? vitaminEMg,
    Value<double?>? vitaminKUg,
    Value<double?>? thiaminMg,
    Value<double?>? riboflavinMg,
    Value<double?>? niacinMg,
    Value<double?>? pantothenicAcidMg,
    Value<double?>? vitaminB6Mg,
    Value<double?>? folateUg,
    Value<double?>? folateDfeUg,
    Value<double?>? vitaminB12Ug,
    Value<double?>? cholineMg,
    Value<double?>? biotinUg,
    Value<double?>? caffeineMg,
    Value<double?>? theobromineMg,
    Value<double?>? lycopeneUg,
    Value<double?>? luteinZeaxanthinUg,
    Value<int>? updatedAt,
    Value<int>? deleted,
    Value<int>? dirty,
    Value<int>? rowid,
  }) {
    return CustomFoodsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      barcode: barcode ?? this.barcode,
      emoji: emoji ?? this.emoji,
      variableFat: variableFat ?? this.variableFat,
      servingG: servingG ?? this.servingG,
      servingLabel: servingLabel ?? this.servingLabel,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbG: carbG ?? this.carbG,
      fiberG: fiberG ?? this.fiberG,
      sugarG: sugarG ?? this.sugarG,
      starchG: starchG ?? this.starchG,
      waterG: waterG ?? this.waterG,
      ashG: ashG ?? this.ashG,
      alcoholG: alcoholG ?? this.alcoholG,
      satFatG: satFatG ?? this.satFatG,
      monoFatG: monoFatG ?? this.monoFatG,
      polyFatG: polyFatG ?? this.polyFatG,
      transFatG: transFatG ?? this.transFatG,
      cholesterolMg: cholesterolMg ?? this.cholesterolMg,
      omega3EpaG: omega3EpaG ?? this.omega3EpaG,
      omega3DhaG: omega3DhaG ?? this.omega3DhaG,
      calciumMg: calciumMg ?? this.calciumMg,
      ironMg: ironMg ?? this.ironMg,
      magnesiumMg: magnesiumMg ?? this.magnesiumMg,
      phosphorusMg: phosphorusMg ?? this.phosphorusMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      zincMg: zincMg ?? this.zincMg,
      copperMg: copperMg ?? this.copperMg,
      manganeseMg: manganeseMg ?? this.manganeseMg,
      seleniumUg: seleniumUg ?? this.seleniumUg,
      fluorideUg: fluorideUg ?? this.fluorideUg,
      iodineUg: iodineUg ?? this.iodineUg,
      vitaminARaeUg: vitaminARaeUg ?? this.vitaminARaeUg,
      retinolUg: retinolUg ?? this.retinolUg,
      caroteneBetaUg: caroteneBetaUg ?? this.caroteneBetaUg,
      vitaminCMg: vitaminCMg ?? this.vitaminCMg,
      vitaminDUg: vitaminDUg ?? this.vitaminDUg,
      vitaminEMg: vitaminEMg ?? this.vitaminEMg,
      vitaminKUg: vitaminKUg ?? this.vitaminKUg,
      thiaminMg: thiaminMg ?? this.thiaminMg,
      riboflavinMg: riboflavinMg ?? this.riboflavinMg,
      niacinMg: niacinMg ?? this.niacinMg,
      pantothenicAcidMg: pantothenicAcidMg ?? this.pantothenicAcidMg,
      vitaminB6Mg: vitaminB6Mg ?? this.vitaminB6Mg,
      folateUg: folateUg ?? this.folateUg,
      folateDfeUg: folateDfeUg ?? this.folateDfeUg,
      vitaminB12Ug: vitaminB12Ug ?? this.vitaminB12Ug,
      cholineMg: cholineMg ?? this.cholineMg,
      biotinUg: biotinUg ?? this.biotinUg,
      caffeineMg: caffeineMg ?? this.caffeineMg,
      theobromineMg: theobromineMg ?? this.theobromineMg,
      lycopeneUg: lycopeneUg ?? this.lycopeneUg,
      luteinZeaxanthinUg: luteinZeaxanthinUg ?? this.luteinZeaxanthinUg,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (barcode.present) {
      map['barcode'] = Variable<String>(barcode.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (variableFat.present) {
      map['variable_fat'] = Variable<int>(variableFat.value);
    }
    if (servingG.present) {
      map['serving_g'] = Variable<double>(servingG.value);
    }
    if (servingLabel.present) {
      map['serving_label'] = Variable<String>(servingLabel.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (starchG.present) {
      map['starch_g'] = Variable<double>(starchG.value);
    }
    if (waterG.present) {
      map['water_g'] = Variable<double>(waterG.value);
    }
    if (ashG.present) {
      map['ash_g'] = Variable<double>(ashG.value);
    }
    if (alcoholG.present) {
      map['alcohol_g'] = Variable<double>(alcoholG.value);
    }
    if (satFatG.present) {
      map['sat_fat_g'] = Variable<double>(satFatG.value);
    }
    if (monoFatG.present) {
      map['mono_fat_g'] = Variable<double>(monoFatG.value);
    }
    if (polyFatG.present) {
      map['poly_fat_g'] = Variable<double>(polyFatG.value);
    }
    if (transFatG.present) {
      map['trans_fat_g'] = Variable<double>(transFatG.value);
    }
    if (cholesterolMg.present) {
      map['cholesterol_mg'] = Variable<double>(cholesterolMg.value);
    }
    if (omega3EpaG.present) {
      map['omega3_epa_g'] = Variable<double>(omega3EpaG.value);
    }
    if (omega3DhaG.present) {
      map['omega3_dha_g'] = Variable<double>(omega3DhaG.value);
    }
    if (calciumMg.present) {
      map['calcium_mg'] = Variable<double>(calciumMg.value);
    }
    if (ironMg.present) {
      map['iron_mg'] = Variable<double>(ironMg.value);
    }
    if (magnesiumMg.present) {
      map['magnesium_mg'] = Variable<double>(magnesiumMg.value);
    }
    if (phosphorusMg.present) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg.value);
    }
    if (potassiumMg.present) {
      map['potassium_mg'] = Variable<double>(potassiumMg.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (zincMg.present) {
      map['zinc_mg'] = Variable<double>(zincMg.value);
    }
    if (copperMg.present) {
      map['copper_mg'] = Variable<double>(copperMg.value);
    }
    if (manganeseMg.present) {
      map['manganese_mg'] = Variable<double>(manganeseMg.value);
    }
    if (seleniumUg.present) {
      map['selenium_ug'] = Variable<double>(seleniumUg.value);
    }
    if (fluorideUg.present) {
      map['fluoride_ug'] = Variable<double>(fluorideUg.value);
    }
    if (iodineUg.present) {
      map['iodine_ug'] = Variable<double>(iodineUg.value);
    }
    if (vitaminARaeUg.present) {
      map['vitamin_a_rae_ug'] = Variable<double>(vitaminARaeUg.value);
    }
    if (retinolUg.present) {
      map['retinol_ug'] = Variable<double>(retinolUg.value);
    }
    if (caroteneBetaUg.present) {
      map['carotene_beta_ug'] = Variable<double>(caroteneBetaUg.value);
    }
    if (vitaminCMg.present) {
      map['vitamin_c_mg'] = Variable<double>(vitaminCMg.value);
    }
    if (vitaminDUg.present) {
      map['vitamin_d_ug'] = Variable<double>(vitaminDUg.value);
    }
    if (vitaminEMg.present) {
      map['vitamin_e_mg'] = Variable<double>(vitaminEMg.value);
    }
    if (vitaminKUg.present) {
      map['vitamin_k_ug'] = Variable<double>(vitaminKUg.value);
    }
    if (thiaminMg.present) {
      map['thiamin_mg'] = Variable<double>(thiaminMg.value);
    }
    if (riboflavinMg.present) {
      map['riboflavin_mg'] = Variable<double>(riboflavinMg.value);
    }
    if (niacinMg.present) {
      map['niacin_mg'] = Variable<double>(niacinMg.value);
    }
    if (pantothenicAcidMg.present) {
      map['pantothenic_acid_mg'] = Variable<double>(pantothenicAcidMg.value);
    }
    if (vitaminB6Mg.present) {
      map['vitamin_b6_mg'] = Variable<double>(vitaminB6Mg.value);
    }
    if (folateUg.present) {
      map['folate_ug'] = Variable<double>(folateUg.value);
    }
    if (folateDfeUg.present) {
      map['folate_dfe_ug'] = Variable<double>(folateDfeUg.value);
    }
    if (vitaminB12Ug.present) {
      map['vitamin_b12_ug'] = Variable<double>(vitaminB12Ug.value);
    }
    if (cholineMg.present) {
      map['choline_mg'] = Variable<double>(cholineMg.value);
    }
    if (biotinUg.present) {
      map['biotin_ug'] = Variable<double>(biotinUg.value);
    }
    if (caffeineMg.present) {
      map['caffeine_mg'] = Variable<double>(caffeineMg.value);
    }
    if (theobromineMg.present) {
      map['theobromine_mg'] = Variable<double>(theobromineMg.value);
    }
    if (lycopeneUg.present) {
      map['lycopene_ug'] = Variable<double>(lycopeneUg.value);
    }
    if (luteinZeaxanthinUg.present) {
      map['lutein_zeaxanthin_ug'] = Variable<double>(luteinZeaxanthinUg.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<int>(deleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<int>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('barcode: $barcode, ')
          ..write('emoji: $emoji, ')
          ..write('variableFat: $variableFat, ')
          ..write('servingG: $servingG, ')
          ..write('servingLabel: $servingLabel, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('starchG: $starchG, ')
          ..write('waterG: $waterG, ')
          ..write('ashG: $ashG, ')
          ..write('alcoholG: $alcoholG, ')
          ..write('satFatG: $satFatG, ')
          ..write('monoFatG: $monoFatG, ')
          ..write('polyFatG: $polyFatG, ')
          ..write('transFatG: $transFatG, ')
          ..write('cholesterolMg: $cholesterolMg, ')
          ..write('omega3EpaG: $omega3EpaG, ')
          ..write('omega3DhaG: $omega3DhaG, ')
          ..write('calciumMg: $calciumMg, ')
          ..write('ironMg: $ironMg, ')
          ..write('magnesiumMg: $magnesiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('zincMg: $zincMg, ')
          ..write('copperMg: $copperMg, ')
          ..write('manganeseMg: $manganeseMg, ')
          ..write('seleniumUg: $seleniumUg, ')
          ..write('fluorideUg: $fluorideUg, ')
          ..write('iodineUg: $iodineUg, ')
          ..write('vitaminARaeUg: $vitaminARaeUg, ')
          ..write('retinolUg: $retinolUg, ')
          ..write('caroteneBetaUg: $caroteneBetaUg, ')
          ..write('vitaminCMg: $vitaminCMg, ')
          ..write('vitaminDUg: $vitaminDUg, ')
          ..write('vitaminEMg: $vitaminEMg, ')
          ..write('vitaminKUg: $vitaminKUg, ')
          ..write('thiaminMg: $thiaminMg, ')
          ..write('riboflavinMg: $riboflavinMg, ')
          ..write('niacinMg: $niacinMg, ')
          ..write('pantothenicAcidMg: $pantothenicAcidMg, ')
          ..write('vitaminB6Mg: $vitaminB6Mg, ')
          ..write('folateUg: $folateUg, ')
          ..write('folateDfeUg: $folateDfeUg, ')
          ..write('vitaminB12Ug: $vitaminB12Ug, ')
          ..write('cholineMg: $cholineMg, ')
          ..write('biotinUg: $biotinUg, ')
          ..write('caffeineMg: $caffeineMg, ')
          ..write('theobromineMg: $theobromineMg, ')
          ..write('lycopeneUg: $lycopeneUg, ')
          ..write('luteinZeaxanthinUg: $luteinZeaxanthinUg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CustomFoodPortions extends Table
    with TableInfo<CustomFoodPortions, CustomFoodPortion> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CustomFoodPortions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _customFoodIdMeta = const VerificationMeta(
    'customFoodId',
  );
  late final GeneratedColumn<String> customFoodId = GeneratedColumn<String>(
    'custom_food_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES custom_foods(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _labelMeta = const VerificationMeta('label');
  late final GeneratedColumn<String> label = GeneratedColumn<String>(
    'label',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _gramWeightMeta = const VerificationMeta(
    'gramWeight',
  );
  late final GeneratedColumn<double> gramWeight = GeneratedColumn<double>(
    'gram_weight',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [customFoodId, seq, label, gramWeight];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'custom_food_portions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CustomFoodPortion> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('custom_food_id')) {
      context.handle(
        _customFoodIdMeta,
        customFoodId.isAcceptableOrUnknown(
          data['custom_food_id']!,
          _customFoodIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_customFoodIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('label')) {
      context.handle(
        _labelMeta,
        label.isAcceptableOrUnknown(data['label']!, _labelMeta),
      );
    } else if (isInserting) {
      context.missing(_labelMeta);
    }
    if (data.containsKey('gram_weight')) {
      context.handle(
        _gramWeightMeta,
        gramWeight.isAcceptableOrUnknown(data['gram_weight']!, _gramWeightMeta),
      );
    } else if (isInserting) {
      context.missing(_gramWeightMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {customFoodId, seq};
  @override
  CustomFoodPortion map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CustomFoodPortion(
      customFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_food_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      label: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}label'],
      )!,
      gramWeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}gram_weight'],
      )!,
    );
  }

  @override
  CustomFoodPortions createAlias(String alias) {
    return CustomFoodPortions(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(custom_food_id, seq)',
    'CHECK(gram_weight > 0 AND length(trim(label)) > 0)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CustomFoodPortion extends DataClass
    implements Insertable<CustomFoodPortion> {
  final String customFoodId;
  final int seq;
  final String label;
  final double gramWeight;
  const CustomFoodPortion({
    required this.customFoodId,
    required this.seq,
    required this.label,
    required this.gramWeight,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['custom_food_id'] = Variable<String>(customFoodId);
    map['seq'] = Variable<int>(seq);
    map['label'] = Variable<String>(label);
    map['gram_weight'] = Variable<double>(gramWeight);
    return map;
  }

  CustomFoodPortionsCompanion toCompanion(bool nullToAbsent) {
    return CustomFoodPortionsCompanion(
      customFoodId: Value(customFoodId),
      seq: Value(seq),
      label: Value(label),
      gramWeight: Value(gramWeight),
    );
  }

  factory CustomFoodPortion.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CustomFoodPortion(
      customFoodId: serializer.fromJson<String>(json['custom_food_id']),
      seq: serializer.fromJson<int>(json['seq']),
      label: serializer.fromJson<String>(json['label']),
      gramWeight: serializer.fromJson<double>(json['gram_weight']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'custom_food_id': serializer.toJson<String>(customFoodId),
      'seq': serializer.toJson<int>(seq),
      'label': serializer.toJson<String>(label),
      'gram_weight': serializer.toJson<double>(gramWeight),
    };
  }

  CustomFoodPortion copyWith({
    String? customFoodId,
    int? seq,
    String? label,
    double? gramWeight,
  }) => CustomFoodPortion(
    customFoodId: customFoodId ?? this.customFoodId,
    seq: seq ?? this.seq,
    label: label ?? this.label,
    gramWeight: gramWeight ?? this.gramWeight,
  );
  CustomFoodPortion copyWithCompanion(CustomFoodPortionsCompanion data) {
    return CustomFoodPortion(
      customFoodId: data.customFoodId.present
          ? data.customFoodId.value
          : this.customFoodId,
      seq: data.seq.present ? data.seq.value : this.seq,
      label: data.label.present ? data.label.value : this.label,
      gramWeight: data.gramWeight.present
          ? data.gramWeight.value
          : this.gramWeight,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodPortion(')
          ..write('customFoodId: $customFoodId, ')
          ..write('seq: $seq, ')
          ..write('label: $label, ')
          ..write('gramWeight: $gramWeight')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(customFoodId, seq, label, gramWeight);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CustomFoodPortion &&
          other.customFoodId == this.customFoodId &&
          other.seq == this.seq &&
          other.label == this.label &&
          other.gramWeight == this.gramWeight);
}

class CustomFoodPortionsCompanion extends UpdateCompanion<CustomFoodPortion> {
  final Value<String> customFoodId;
  final Value<int> seq;
  final Value<String> label;
  final Value<double> gramWeight;
  const CustomFoodPortionsCompanion({
    this.customFoodId = const Value.absent(),
    this.seq = const Value.absent(),
    this.label = const Value.absent(),
    this.gramWeight = const Value.absent(),
  });
  CustomFoodPortionsCompanion.insert({
    required String customFoodId,
    required int seq,
    required String label,
    required double gramWeight,
  }) : customFoodId = Value(customFoodId),
       seq = Value(seq),
       label = Value(label),
       gramWeight = Value(gramWeight);
  static Insertable<CustomFoodPortion> custom({
    Expression<String>? customFoodId,
    Expression<int>? seq,
    Expression<String>? label,
    Expression<double>? gramWeight,
  }) {
    return RawValuesInsertable({
      if (customFoodId != null) 'custom_food_id': customFoodId,
      if (seq != null) 'seq': seq,
      if (label != null) 'label': label,
      if (gramWeight != null) 'gram_weight': gramWeight,
    });
  }

  CustomFoodPortionsCompanion copyWith({
    Value<String>? customFoodId,
    Value<int>? seq,
    Value<String>? label,
    Value<double>? gramWeight,
  }) {
    return CustomFoodPortionsCompanion(
      customFoodId: customFoodId ?? this.customFoodId,
      seq: seq ?? this.seq,
      label: label ?? this.label,
      gramWeight: gramWeight ?? this.gramWeight,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (customFoodId.present) {
      map['custom_food_id'] = Variable<String>(customFoodId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (label.present) {
      map['label'] = Variable<String>(label.value);
    }
    if (gramWeight.present) {
      map['gram_weight'] = Variable<double>(gramWeight.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CustomFoodPortionsCompanion(')
          ..write('customFoodId: $customFoodId, ')
          ..write('seq: $seq, ')
          ..write('label: $label, ')
          ..write('gramWeight: $gramWeight')
          ..write(')'))
        .toString();
  }
}

class RecipeIngredients extends Table
    with TableInfo<RecipeIngredients, RecipeIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecipeIngredients(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES custom_foods(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _customFoodIdMeta = const VerificationMeta(
    'customFoodId',
  );
  late final GeneratedColumn<String> customFoodId = GeneratedColumn<String>(
    'custom_food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES custom_foods(id)',
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    recipeId,
    seq,
    foodId,
    customFoodId,
    grams,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('custom_food_id')) {
      context.handle(
        _customFoodIdMeta,
        customFoodId.isAcceptableOrUnknown(
          data['custom_food_id']!,
          _customFoodIdMeta,
        ),
      );
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, seq};
  @override
  RecipeIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeIngredient(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      ),
      customFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_food_id'],
      ),
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
    );
  }

  @override
  RecipeIngredients createAlias(String alias) {
    return RecipeIngredients(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(recipe_id, seq)',
    'CHECK((food_id IS NULL)<>(custom_food_id IS NULL))',
    'CHECK(custom_food_id IS NULL OR custom_food_id <> recipe_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RecipeIngredient extends DataClass
    implements Insertable<RecipeIngredient> {
  final String recipeId;
  final int seq;
  final int? foodId;
  final String? customFoodId;
  final double grams;
  const RecipeIngredient({
    required this.recipeId,
    required this.seq,
    this.foodId,
    this.customFoodId,
    required this.grams,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['seq'] = Variable<int>(seq);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<int>(foodId);
    }
    if (!nullToAbsent || customFoodId != null) {
      map['custom_food_id'] = Variable<String>(customFoodId);
    }
    map['grams'] = Variable<double>(grams);
    return map;
  }

  RecipeIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeIngredientsCompanion(
      recipeId: Value(recipeId),
      seq: Value(seq),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      customFoodId: customFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(customFoodId),
      grams: Value(grams),
    );
  }

  factory RecipeIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeIngredient(
      recipeId: serializer.fromJson<String>(json['recipe_id']),
      seq: serializer.fromJson<int>(json['seq']),
      foodId: serializer.fromJson<int?>(json['food_id']),
      customFoodId: serializer.fromJson<String?>(json['custom_food_id']),
      grams: serializer.fromJson<double>(json['grams']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipe_id': serializer.toJson<String>(recipeId),
      'seq': serializer.toJson<int>(seq),
      'food_id': serializer.toJson<int?>(foodId),
      'custom_food_id': serializer.toJson<String?>(customFoodId),
      'grams': serializer.toJson<double>(grams),
    };
  }

  RecipeIngredient copyWith({
    String? recipeId,
    int? seq,
    Value<int?> foodId = const Value.absent(),
    Value<String?> customFoodId = const Value.absent(),
    double? grams,
  }) => RecipeIngredient(
    recipeId: recipeId ?? this.recipeId,
    seq: seq ?? this.seq,
    foodId: foodId.present ? foodId.value : this.foodId,
    customFoodId: customFoodId.present ? customFoodId.value : this.customFoodId,
    grams: grams ?? this.grams,
  );
  RecipeIngredient copyWithCompanion(RecipeIngredientsCompanion data) {
    return RecipeIngredient(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      seq: data.seq.present ? data.seq.value : this.seq,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      customFoodId: data.customFoodId.present
          ? data.customFoodId.value
          : this.customFoodId,
      grams: data.grams.present ? data.grams.value : this.grams,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredient(')
          ..write('recipeId: $recipeId, ')
          ..write('seq: $seq, ')
          ..write('foodId: $foodId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, seq, foodId, customFoodId, grams);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeIngredient &&
          other.recipeId == this.recipeId &&
          other.seq == this.seq &&
          other.foodId == this.foodId &&
          other.customFoodId == this.customFoodId &&
          other.grams == this.grams);
}

class RecipeIngredientsCompanion extends UpdateCompanion<RecipeIngredient> {
  final Value<String> recipeId;
  final Value<int> seq;
  final Value<int?> foodId;
  final Value<String?> customFoodId;
  final Value<double> grams;
  const RecipeIngredientsCompanion({
    this.recipeId = const Value.absent(),
    this.seq = const Value.absent(),
    this.foodId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    this.grams = const Value.absent(),
  });
  RecipeIngredientsCompanion.insert({
    required String recipeId,
    required int seq,
    this.foodId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    required double grams,
  }) : recipeId = Value(recipeId),
       seq = Value(seq),
       grams = Value(grams);
  static Insertable<RecipeIngredient> custom({
    Expression<String>? recipeId,
    Expression<int>? seq,
    Expression<int>? foodId,
    Expression<String>? customFoodId,
    Expression<double>? grams,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (seq != null) 'seq': seq,
      if (foodId != null) 'food_id': foodId,
      if (customFoodId != null) 'custom_food_id': customFoodId,
      if (grams != null) 'grams': grams,
    });
  }

  RecipeIngredientsCompanion copyWith({
    Value<String>? recipeId,
    Value<int>? seq,
    Value<int?>? foodId,
    Value<String?>? customFoodId,
    Value<double>? grams,
  }) {
    return RecipeIngredientsCompanion(
      recipeId: recipeId ?? this.recipeId,
      seq: seq ?? this.seq,
      foodId: foodId ?? this.foodId,
      customFoodId: customFoodId ?? this.customFoodId,
      grams: grams ?? this.grams,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (customFoodId.present) {
      map['custom_food_id'] = Variable<String>(customFoodId.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeIngredientsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('seq: $seq, ')
          ..write('foodId: $foodId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('grams: $grams')
          ..write(')'))
        .toString();
  }
}

class RecipeSteps extends Table with TableInfo<RecipeSteps, RecipeStep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecipeSteps(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES custom_foods(id)ON DELETE CASCADE',
  );
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
    'seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stepTextMeta = const VerificationMeta(
    'stepText',
  );
  late final GeneratedColumn<String> stepText = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _durationSMeta = const VerificationMeta(
    'durationS',
  );
  late final GeneratedColumn<int> durationS = GeneratedColumn<int>(
    'duration_s',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId, seq, stepText, durationS];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_steps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('seq')) {
      context.handle(
        _seqMeta,
        seq.isAcceptableOrUnknown(data['seq']!, _seqMeta),
      );
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _stepTextMeta,
        stepText.isAcceptableOrUnknown(data['text']!, _stepTextMeta),
      );
    } else if (isInserting) {
      context.missing(_stepTextMeta);
    }
    if (data.containsKey('duration_s')) {
      context.handle(
        _durationSMeta,
        durationS.isAcceptableOrUnknown(data['duration_s']!, _durationSMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, seq};
  @override
  RecipeStep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStep(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      seq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}seq'],
      )!,
      stepText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      durationS: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_s'],
      ),
    );
  }

  @override
  RecipeSteps createAlias(String alias) {
    return RecipeSteps(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(recipe_id, seq)',
    'CHECK(length(trim(text)) > 0)',
    'CHECK(duration_s IS NULL OR duration_s > 0)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RecipeStep extends DataClass implements Insertable<RecipeStep> {
  final String recipeId;
  final int seq;

  /// `AS <name>` renames only the Dart getter; the SQL column stays `text`.
  /// Needed because `text` collides with drift's Table.text() column builder.
  final String stepText;
  final int? durationS;
  const RecipeStep({
    required this.recipeId,
    required this.seq,
    required this.stepText,
    this.durationS,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['seq'] = Variable<int>(seq);
    map['text'] = Variable<String>(stepText);
    if (!nullToAbsent || durationS != null) {
      map['duration_s'] = Variable<int>(durationS);
    }
    return map;
  }

  RecipeStepsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepsCompanion(
      recipeId: Value(recipeId),
      seq: Value(seq),
      stepText: Value(stepText),
      durationS: durationS == null && nullToAbsent
          ? const Value.absent()
          : Value(durationS),
    );
  }

  factory RecipeStep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStep(
      recipeId: serializer.fromJson<String>(json['recipe_id']),
      seq: serializer.fromJson<int>(json['seq']),
      stepText: serializer.fromJson<String>(json['text']),
      durationS: serializer.fromJson<int?>(json['duration_s']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipe_id': serializer.toJson<String>(recipeId),
      'seq': serializer.toJson<int>(seq),
      'text': serializer.toJson<String>(stepText),
      'duration_s': serializer.toJson<int?>(durationS),
    };
  }

  RecipeStep copyWith({
    String? recipeId,
    int? seq,
    String? stepText,
    Value<int?> durationS = const Value.absent(),
  }) => RecipeStep(
    recipeId: recipeId ?? this.recipeId,
    seq: seq ?? this.seq,
    stepText: stepText ?? this.stepText,
    durationS: durationS.present ? durationS.value : this.durationS,
  );
  RecipeStep copyWithCompanion(RecipeStepsCompanion data) {
    return RecipeStep(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      seq: data.seq.present ? data.seq.value : this.seq,
      stepText: data.stepText.present ? data.stepText.value : this.stepText,
      durationS: data.durationS.present ? data.durationS.value : this.durationS,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStep(')
          ..write('recipeId: $recipeId, ')
          ..write('seq: $seq, ')
          ..write('stepText: $stepText, ')
          ..write('durationS: $durationS')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, seq, stepText, durationS);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStep &&
          other.recipeId == this.recipeId &&
          other.seq == this.seq &&
          other.stepText == this.stepText &&
          other.durationS == this.durationS);
}

class RecipeStepsCompanion extends UpdateCompanion<RecipeStep> {
  final Value<String> recipeId;
  final Value<int> seq;
  final Value<String> stepText;
  final Value<int?> durationS;
  const RecipeStepsCompanion({
    this.recipeId = const Value.absent(),
    this.seq = const Value.absent(),
    this.stepText = const Value.absent(),
    this.durationS = const Value.absent(),
  });
  RecipeStepsCompanion.insert({
    required String recipeId,
    required int seq,
    required String stepText,
    this.durationS = const Value.absent(),
  }) : recipeId = Value(recipeId),
       seq = Value(seq),
       stepText = Value(stepText);
  static Insertable<RecipeStep> custom({
    Expression<String>? recipeId,
    Expression<int>? seq,
    Expression<String>? stepText,
    Expression<int>? durationS,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (seq != null) 'seq': seq,
      if (stepText != null) 'text': stepText,
      if (durationS != null) 'duration_s': durationS,
    });
  }

  RecipeStepsCompanion copyWith({
    Value<String>? recipeId,
    Value<int>? seq,
    Value<String>? stepText,
    Value<int?>? durationS,
  }) {
    return RecipeStepsCompanion(
      recipeId: recipeId ?? this.recipeId,
      seq: seq ?? this.seq,
      stepText: stepText ?? this.stepText,
      durationS: durationS ?? this.durationS,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (stepText.present) {
      map['text'] = Variable<String>(stepText.value);
    }
    if (durationS.present) {
      map['duration_s'] = Variable<int>(durationS.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('seq: $seq, ')
          ..write('stepText: $stepText, ')
          ..write('durationS: $durationS')
          ..write(')'))
        .toString();
  }
}

class RecipeStepIngredients extends Table
    with TableInfo<RecipeStepIngredients, RecipeStepIngredient> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RecipeStepIngredients(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _stepSeqMeta = const VerificationMeta(
    'stepSeq',
  );
  late final GeneratedColumn<int> stepSeq = GeneratedColumn<int>(
    'step_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _ingredientSeqMeta = const VerificationMeta(
    'ingredientSeq',
  );
  late final GeneratedColumn<int> ingredientSeq = GeneratedColumn<int>(
    'ingredient_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId, stepSeq, ingredientSeq];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'recipe_step_ingredients';
  @override
  VerificationContext validateIntegrity(
    Insertable<RecipeStepIngredient> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recipeIdMeta);
    }
    if (data.containsKey('step_seq')) {
      context.handle(
        _stepSeqMeta,
        stepSeq.isAcceptableOrUnknown(data['step_seq']!, _stepSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_stepSeqMeta);
    }
    if (data.containsKey('ingredient_seq')) {
      context.handle(
        _ingredientSeqMeta,
        ingredientSeq.isAcceptableOrUnknown(
          data['ingredient_seq']!,
          _ingredientSeqMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_ingredientSeqMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId, stepSeq, ingredientSeq};
  @override
  RecipeStepIngredient map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RecipeStepIngredient(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      )!,
      stepSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_seq'],
      )!,
      ingredientSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ingredient_seq'],
      )!,
    );
  }

  @override
  RecipeStepIngredients createAlias(String alias) {
    return RecipeStepIngredients(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(recipe_id, step_seq, ingredient_seq)',
    'FOREIGN KEY(recipe_id, step_seq)REFERENCES recipe_steps(recipe_id, seq)ON DELETE CASCADE',
    'FOREIGN KEY(recipe_id, ingredient_seq)REFERENCES recipe_ingredients(recipe_id, seq)ON DELETE CASCADE',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RecipeStepIngredient extends DataClass
    implements Insertable<RecipeStepIngredient> {
  final String recipeId;
  final int stepSeq;
  final int ingredientSeq;
  const RecipeStepIngredient({
    required this.recipeId,
    required this.stepSeq,
    required this.ingredientSeq,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['recipe_id'] = Variable<String>(recipeId);
    map['step_seq'] = Variable<int>(stepSeq);
    map['ingredient_seq'] = Variable<int>(ingredientSeq);
    return map;
  }

  RecipeStepIngredientsCompanion toCompanion(bool nullToAbsent) {
    return RecipeStepIngredientsCompanion(
      recipeId: Value(recipeId),
      stepSeq: Value(stepSeq),
      ingredientSeq: Value(ingredientSeq),
    );
  }

  factory RecipeStepIngredient.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RecipeStepIngredient(
      recipeId: serializer.fromJson<String>(json['recipe_id']),
      stepSeq: serializer.fromJson<int>(json['step_seq']),
      ingredientSeq: serializer.fromJson<int>(json['ingredient_seq']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipe_id': serializer.toJson<String>(recipeId),
      'step_seq': serializer.toJson<int>(stepSeq),
      'ingredient_seq': serializer.toJson<int>(ingredientSeq),
    };
  }

  RecipeStepIngredient copyWith({
    String? recipeId,
    int? stepSeq,
    int? ingredientSeq,
  }) => RecipeStepIngredient(
    recipeId: recipeId ?? this.recipeId,
    stepSeq: stepSeq ?? this.stepSeq,
    ingredientSeq: ingredientSeq ?? this.ingredientSeq,
  );
  RecipeStepIngredient copyWithCompanion(RecipeStepIngredientsCompanion data) {
    return RecipeStepIngredient(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      stepSeq: data.stepSeq.present ? data.stepSeq.value : this.stepSeq,
      ingredientSeq: data.ingredientSeq.present
          ? data.ingredientSeq.value
          : this.ingredientSeq,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepIngredient(')
          ..write('recipeId: $recipeId, ')
          ..write('stepSeq: $stepSeq, ')
          ..write('ingredientSeq: $ingredientSeq')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, stepSeq, ingredientSeq);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RecipeStepIngredient &&
          other.recipeId == this.recipeId &&
          other.stepSeq == this.stepSeq &&
          other.ingredientSeq == this.ingredientSeq);
}

class RecipeStepIngredientsCompanion
    extends UpdateCompanion<RecipeStepIngredient> {
  final Value<String> recipeId;
  final Value<int> stepSeq;
  final Value<int> ingredientSeq;
  const RecipeStepIngredientsCompanion({
    this.recipeId = const Value.absent(),
    this.stepSeq = const Value.absent(),
    this.ingredientSeq = const Value.absent(),
  });
  RecipeStepIngredientsCompanion.insert({
    required String recipeId,
    required int stepSeq,
    required int ingredientSeq,
  }) : recipeId = Value(recipeId),
       stepSeq = Value(stepSeq),
       ingredientSeq = Value(ingredientSeq);
  static Insertable<RecipeStepIngredient> custom({
    Expression<String>? recipeId,
    Expression<int>? stepSeq,
    Expression<int>? ingredientSeq,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (stepSeq != null) 'step_seq': stepSeq,
      if (ingredientSeq != null) 'ingredient_seq': ingredientSeq,
    });
  }

  RecipeStepIngredientsCompanion copyWith({
    Value<String>? recipeId,
    Value<int>? stepSeq,
    Value<int>? ingredientSeq,
  }) {
    return RecipeStepIngredientsCompanion(
      recipeId: recipeId ?? this.recipeId,
      stepSeq: stepSeq ?? this.stepSeq,
      ingredientSeq: ingredientSeq ?? this.ingredientSeq,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (stepSeq.present) {
      map['step_seq'] = Variable<int>(stepSeq.value);
    }
    if (ingredientSeq.present) {
      map['ingredient_seq'] = Variable<int>(ingredientSeq.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RecipeStepIngredientsCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('stepSeq: $stepSeq, ')
          ..write('ingredientSeq: $ingredientSeq')
          ..write(')'))
        .toString();
  }
}

class CookSession extends Table with TableInfo<CookSession, CookSessionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CookSession(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recipeIdMeta = const VerificationMeta(
    'recipeId',
  );
  late final GeneratedColumn<String> recipeId = GeneratedColumn<String>(
    'recipe_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _stepSeqMeta = const VerificationMeta(
    'stepSeq',
  );
  late final GeneratedColumn<int> stepSeq = GeneratedColumn<int>(
    'step_seq',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT (strftime(\'%s\', \'now\'))',
    defaultValue: const CustomExpression('strftime(\'%s\', \'now\')'),
  );
  @override
  List<GeneratedColumn> get $columns => [recipeId, stepSeq, startedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cook_session';
  @override
  VerificationContext validateIntegrity(
    Insertable<CookSessionData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('recipe_id')) {
      context.handle(
        _recipeIdMeta,
        recipeId.isAcceptableOrUnknown(data['recipe_id']!, _recipeIdMeta),
      );
    }
    if (data.containsKey('step_seq')) {
      context.handle(
        _stepSeqMeta,
        stepSeq.isAcceptableOrUnknown(data['step_seq']!, _stepSeqMeta),
      );
    } else if (isInserting) {
      context.missing(_stepSeqMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recipeId};
  @override
  CookSessionData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CookSessionData(
      recipeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recipe_id'],
      ),
      stepSeq: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}step_seq'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at'],
      )!,
    );
  }

  @override
  CookSession createAlias(String alias) {
    return CookSession(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  List<String> get customConstraints => const [
    'FOREIGN KEY(recipe_id, step_seq)REFERENCES recipe_steps(recipe_id, seq)ON DELETE CASCADE',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CookSessionData extends DataClass implements Insertable<CookSessionData> {
  final String? recipeId;
  final int stepSeq;
  final int startedAt;
  const CookSessionData({
    this.recipeId,
    required this.stepSeq,
    required this.startedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || recipeId != null) {
      map['recipe_id'] = Variable<String>(recipeId);
    }
    map['step_seq'] = Variable<int>(stepSeq);
    map['started_at'] = Variable<int>(startedAt);
    return map;
  }

  CookSessionCompanion toCompanion(bool nullToAbsent) {
    return CookSessionCompanion(
      recipeId: recipeId == null && nullToAbsent
          ? const Value.absent()
          : Value(recipeId),
      stepSeq: Value(stepSeq),
      startedAt: Value(startedAt),
    );
  }

  factory CookSessionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CookSessionData(
      recipeId: serializer.fromJson<String?>(json['recipe_id']),
      stepSeq: serializer.fromJson<int>(json['step_seq']),
      startedAt: serializer.fromJson<int>(json['started_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recipe_id': serializer.toJson<String?>(recipeId),
      'step_seq': serializer.toJson<int>(stepSeq),
      'started_at': serializer.toJson<int>(startedAt),
    };
  }

  CookSessionData copyWith({
    Value<String?> recipeId = const Value.absent(),
    int? stepSeq,
    int? startedAt,
  }) => CookSessionData(
    recipeId: recipeId.present ? recipeId.value : this.recipeId,
    stepSeq: stepSeq ?? this.stepSeq,
    startedAt: startedAt ?? this.startedAt,
  );
  CookSessionData copyWithCompanion(CookSessionCompanion data) {
    return CookSessionData(
      recipeId: data.recipeId.present ? data.recipeId.value : this.recipeId,
      stepSeq: data.stepSeq.present ? data.stepSeq.value : this.stepSeq,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CookSessionData(')
          ..write('recipeId: $recipeId, ')
          ..write('stepSeq: $stepSeq, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recipeId, stepSeq, startedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CookSessionData &&
          other.recipeId == this.recipeId &&
          other.stepSeq == this.stepSeq &&
          other.startedAt == this.startedAt);
}

class CookSessionCompanion extends UpdateCompanion<CookSessionData> {
  final Value<String?> recipeId;
  final Value<int> stepSeq;
  final Value<int> startedAt;
  const CookSessionCompanion({
    this.recipeId = const Value.absent(),
    this.stepSeq = const Value.absent(),
    this.startedAt = const Value.absent(),
  });
  CookSessionCompanion.insert({
    this.recipeId = const Value.absent(),
    required int stepSeq,
    this.startedAt = const Value.absent(),
  }) : stepSeq = Value(stepSeq);
  static Insertable<CookSessionData> custom({
    Expression<String>? recipeId,
    Expression<int>? stepSeq,
    Expression<int>? startedAt,
  }) {
    return RawValuesInsertable({
      if (recipeId != null) 'recipe_id': recipeId,
      if (stepSeq != null) 'step_seq': stepSeq,
      if (startedAt != null) 'started_at': startedAt,
    });
  }

  CookSessionCompanion copyWith({
    Value<String?>? recipeId,
    Value<int>? stepSeq,
    Value<int>? startedAt,
  }) {
    return CookSessionCompanion(
      recipeId: recipeId ?? this.recipeId,
      stepSeq: stepSeq ?? this.stepSeq,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recipeId.present) {
      map['recipe_id'] = Variable<String>(recipeId.value);
    }
    if (stepSeq.present) {
      map['step_seq'] = Variable<int>(stepSeq.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CookSessionCompanion(')
          ..write('recipeId: $recipeId, ')
          ..write('stepSeq: $stepSeq, ')
          ..write('startedAt: $startedAt')
          ..write(')'))
        .toString();
  }
}

class LogEntries extends Table with TableInfo<LogEntries, LogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  LogEntries(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY DEFAULT (lower(hex(randomblob(16))))',
    defaultValue: const CustomExpression('lower(hex(randomblob(16)))'),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  late final GeneratedColumn<int> foodId = GeneratedColumn<int>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _customFoodIdMeta = const VerificationMeta(
    'customFoodId',
  );
  late final GeneratedColumn<String> customFoodId = GeneratedColumn<String>(
    'custom_food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES custom_foods(id)',
  );
  static const VerificationMeta _loggedAtMeta = const VerificationMeta(
    'loggedAt',
  );
  late final GeneratedColumn<String> loggedAt = GeneratedColumn<String>(
    'logged_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    true,
    generatedAs: GeneratedAs(
      const CustomExpression('substr(logged_at, 1, 10)'),
      false,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'GENERATED ALWAYS AS (substr(logged_at, 1, 10)) VIRTUAL',
  );
  static const VerificationMeta _gramsMeta = const VerificationMeta('grams');
  late final GeneratedColumn<double> grams = GeneratedColumn<double>(
    'grams',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _portionQtyMeta = const VerificationMeta(
    'portionQty',
  );
  late final GeneratedColumn<double> portionQty = GeneratedColumn<double>(
    'portion_qty',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _portionLabelMeta = const VerificationMeta(
    'portionLabel',
  );
  late final GeneratedColumn<String> portionLabel = GeneratedColumn<String>(
    'portion_label',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _emojiMeta = const VerificationMeta('emoji');
  late final GeneratedColumn<String> emoji = GeneratedColumn<String>(
    'emoji',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _carbGMeta = const VerificationMeta('carbG');
  late final GeneratedColumn<double> carbG = GeneratedColumn<double>(
    'carb_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _starchGMeta = const VerificationMeta(
    'starchG',
  );
  late final GeneratedColumn<double> starchG = GeneratedColumn<double>(
    'starch_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _waterGMeta = const VerificationMeta('waterG');
  late final GeneratedColumn<double> waterG = GeneratedColumn<double>(
    'water_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ashGMeta = const VerificationMeta('ashG');
  late final GeneratedColumn<double> ashG = GeneratedColumn<double>(
    'ash_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _alcoholGMeta = const VerificationMeta(
    'alcoholG',
  );
  late final GeneratedColumn<double> alcoholG = GeneratedColumn<double>(
    'alcohol_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _satFatGMeta = const VerificationMeta(
    'satFatG',
  );
  late final GeneratedColumn<double> satFatG = GeneratedColumn<double>(
    'sat_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _monoFatGMeta = const VerificationMeta(
    'monoFatG',
  );
  late final GeneratedColumn<double> monoFatG = GeneratedColumn<double>(
    'mono_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _polyFatGMeta = const VerificationMeta(
    'polyFatG',
  );
  late final GeneratedColumn<double> polyFatG = GeneratedColumn<double>(
    'poly_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _transFatGMeta = const VerificationMeta(
    'transFatG',
  );
  late final GeneratedColumn<double> transFatG = GeneratedColumn<double>(
    'trans_fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _cholesterolMgMeta = const VerificationMeta(
    'cholesterolMg',
  );
  late final GeneratedColumn<double> cholesterolMg = GeneratedColumn<double>(
    'cholesterol_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _omega3EpaGMeta = const VerificationMeta(
    'omega3EpaG',
  );
  late final GeneratedColumn<double> omega3EpaG = GeneratedColumn<double>(
    'omega3_epa_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _omega3DhaGMeta = const VerificationMeta(
    'omega3DhaG',
  );
  late final GeneratedColumn<double> omega3DhaG = GeneratedColumn<double>(
    'omega3_dha_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _calciumMgMeta = const VerificationMeta(
    'calciumMg',
  );
  late final GeneratedColumn<double> calciumMg = GeneratedColumn<double>(
    'calcium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _ironMgMeta = const VerificationMeta('ironMg');
  late final GeneratedColumn<double> ironMg = GeneratedColumn<double>(
    'iron_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _magnesiumMgMeta = const VerificationMeta(
    'magnesiumMg',
  );
  late final GeneratedColumn<double> magnesiumMg = GeneratedColumn<double>(
    'magnesium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _phosphorusMgMeta = const VerificationMeta(
    'phosphorusMg',
  );
  late final GeneratedColumn<double> phosphorusMg = GeneratedColumn<double>(
    'phosphorus_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _potassiumMgMeta = const VerificationMeta(
    'potassiumMg',
  );
  late final GeneratedColumn<double> potassiumMg = GeneratedColumn<double>(
    'potassium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _zincMgMeta = const VerificationMeta('zincMg');
  late final GeneratedColumn<double> zincMg = GeneratedColumn<double>(
    'zinc_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _copperMgMeta = const VerificationMeta(
    'copperMg',
  );
  late final GeneratedColumn<double> copperMg = GeneratedColumn<double>(
    'copper_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _manganeseMgMeta = const VerificationMeta(
    'manganeseMg',
  );
  late final GeneratedColumn<double> manganeseMg = GeneratedColumn<double>(
    'manganese_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _seleniumUgMeta = const VerificationMeta(
    'seleniumUg',
  );
  late final GeneratedColumn<double> seleniumUg = GeneratedColumn<double>(
    'selenium_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fluorideUgMeta = const VerificationMeta(
    'fluorideUg',
  );
  late final GeneratedColumn<double> fluorideUg = GeneratedColumn<double>(
    'fluoride_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _iodineUgMeta = const VerificationMeta(
    'iodineUg',
  );
  late final GeneratedColumn<double> iodineUg = GeneratedColumn<double>(
    'iodine_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _vitaminARaeUgMeta = const VerificationMeta(
    'vitaminARaeUg',
  );
  late final GeneratedColumn<double> vitaminARaeUg = GeneratedColumn<double>(
    'vitamin_a_rae_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _retinolUgMeta = const VerificationMeta(
    'retinolUg',
  );
  late final GeneratedColumn<double> retinolUg = GeneratedColumn<double>(
    'retinol_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _caroteneBetaUgMeta = const VerificationMeta(
    'caroteneBetaUg',
  );
  late final GeneratedColumn<double> caroteneBetaUg = GeneratedColumn<double>(
    'carotene_beta_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _vitaminCMgMeta = const VerificationMeta(
    'vitaminCMg',
  );
  late final GeneratedColumn<double> vitaminCMg = GeneratedColumn<double>(
    'vitamin_c_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _vitaminDUgMeta = const VerificationMeta(
    'vitaminDUg',
  );
  late final GeneratedColumn<double> vitaminDUg = GeneratedColumn<double>(
    'vitamin_d_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _vitaminEMgMeta = const VerificationMeta(
    'vitaminEMg',
  );
  late final GeneratedColumn<double> vitaminEMg = GeneratedColumn<double>(
    'vitamin_e_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _vitaminKUgMeta = const VerificationMeta(
    'vitaminKUg',
  );
  late final GeneratedColumn<double> vitaminKUg = GeneratedColumn<double>(
    'vitamin_k_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _thiaminMgMeta = const VerificationMeta(
    'thiaminMg',
  );
  late final GeneratedColumn<double> thiaminMg = GeneratedColumn<double>(
    'thiamin_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _riboflavinMgMeta = const VerificationMeta(
    'riboflavinMg',
  );
  late final GeneratedColumn<double> riboflavinMg = GeneratedColumn<double>(
    'riboflavin_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _niacinMgMeta = const VerificationMeta(
    'niacinMg',
  );
  late final GeneratedColumn<double> niacinMg = GeneratedColumn<double>(
    'niacin_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _pantothenicAcidMgMeta = const VerificationMeta(
    'pantothenicAcidMg',
  );
  late final GeneratedColumn<double> pantothenicAcidMg =
      GeneratedColumn<double>(
        'pantothenic_acid_mg',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _vitaminB6MgMeta = const VerificationMeta(
    'vitaminB6Mg',
  );
  late final GeneratedColumn<double> vitaminB6Mg = GeneratedColumn<double>(
    'vitamin_b6_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _folateUgMeta = const VerificationMeta(
    'folateUg',
  );
  late final GeneratedColumn<double> folateUg = GeneratedColumn<double>(
    'folate_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _folateDfeUgMeta = const VerificationMeta(
    'folateDfeUg',
  );
  late final GeneratedColumn<double> folateDfeUg = GeneratedColumn<double>(
    'folate_dfe_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _vitaminB12UgMeta = const VerificationMeta(
    'vitaminB12Ug',
  );
  late final GeneratedColumn<double> vitaminB12Ug = GeneratedColumn<double>(
    'vitamin_b12_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _cholineMgMeta = const VerificationMeta(
    'cholineMg',
  );
  late final GeneratedColumn<double> cholineMg = GeneratedColumn<double>(
    'choline_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _biotinUgMeta = const VerificationMeta(
    'biotinUg',
  );
  late final GeneratedColumn<double> biotinUg = GeneratedColumn<double>(
    'biotin_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _caffeineMgMeta = const VerificationMeta(
    'caffeineMg',
  );
  late final GeneratedColumn<double> caffeineMg = GeneratedColumn<double>(
    'caffeine_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _theobromineMgMeta = const VerificationMeta(
    'theobromineMg',
  );
  late final GeneratedColumn<double> theobromineMg = GeneratedColumn<double>(
    'theobromine_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lycopeneUgMeta = const VerificationMeta(
    'lycopeneUg',
  );
  late final GeneratedColumn<double> lycopeneUg = GeneratedColumn<double>(
    'lycopene_ug',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _luteinZeaxanthinUgMeta =
      const VerificationMeta('luteinZeaxanthinUg');
  late final GeneratedColumn<double> luteinZeaxanthinUg =
      GeneratedColumn<double>(
        'lutein_zeaxanthin_ug',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT (strftime(\'%s\', \'now\'))',
    defaultValue: const CustomExpression('strftime(\'%s\', \'now\')'),
  );
  static const VerificationMeta _deletedMeta = const VerificationMeta(
    'deleted',
  );
  late final GeneratedColumn<int> deleted = GeneratedColumn<int>(
    'deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  late final GeneratedColumn<int> dirty = GeneratedColumn<int>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1',
    defaultValue: const CustomExpression('1'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    foodId,
    customFoodId,
    loggedAt,
    localDate,
    grams,
    portionQty,
    portionLabel,
    name,
    emoji,
    energyKcal,
    proteinG,
    fatG,
    carbG,
    fiberG,
    sugarG,
    starchG,
    waterG,
    ashG,
    alcoholG,
    satFatG,
    monoFatG,
    polyFatG,
    transFatG,
    cholesterolMg,
    omega3EpaG,
    omega3DhaG,
    calciumMg,
    ironMg,
    magnesiumMg,
    phosphorusMg,
    potassiumMg,
    sodiumMg,
    zincMg,
    copperMg,
    manganeseMg,
    seleniumUg,
    fluorideUg,
    iodineUg,
    vitaminARaeUg,
    retinolUg,
    caroteneBetaUg,
    vitaminCMg,
    vitaminDUg,
    vitaminEMg,
    vitaminKUg,
    thiaminMg,
    riboflavinMg,
    niacinMg,
    pantothenicAcidMg,
    vitaminB6Mg,
    folateUg,
    folateDfeUg,
    vitaminB12Ug,
    cholineMg,
    biotinUg,
    caffeineMg,
    theobromineMg,
    lycopeneUg,
    luteinZeaxanthinUg,
    updatedAt,
    deleted,
    dirty,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'log_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('custom_food_id')) {
      context.handle(
        _customFoodIdMeta,
        customFoodId.isAcceptableOrUnknown(
          data['custom_food_id']!,
          _customFoodIdMeta,
        ),
      );
    }
    if (data.containsKey('logged_at')) {
      context.handle(
        _loggedAtMeta,
        loggedAt.isAcceptableOrUnknown(data['logged_at']!, _loggedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_loggedAtMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    }
    if (data.containsKey('grams')) {
      context.handle(
        _gramsMeta,
        grams.isAcceptableOrUnknown(data['grams']!, _gramsMeta),
      );
    } else if (isInserting) {
      context.missing(_gramsMeta);
    }
    if (data.containsKey('portion_qty')) {
      context.handle(
        _portionQtyMeta,
        portionQty.isAcceptableOrUnknown(data['portion_qty']!, _portionQtyMeta),
      );
    }
    if (data.containsKey('portion_label')) {
      context.handle(
        _portionLabelMeta,
        portionLabel.isAcceptableOrUnknown(
          data['portion_label']!,
          _portionLabelMeta,
        ),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('emoji')) {
      context.handle(
        _emojiMeta,
        emoji.isAcceptableOrUnknown(data['emoji']!, _emojiMeta),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('carb_g')) {
      context.handle(
        _carbGMeta,
        carbG.isAcceptableOrUnknown(data['carb_g']!, _carbGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('starch_g')) {
      context.handle(
        _starchGMeta,
        starchG.isAcceptableOrUnknown(data['starch_g']!, _starchGMeta),
      );
    }
    if (data.containsKey('water_g')) {
      context.handle(
        _waterGMeta,
        waterG.isAcceptableOrUnknown(data['water_g']!, _waterGMeta),
      );
    }
    if (data.containsKey('ash_g')) {
      context.handle(
        _ashGMeta,
        ashG.isAcceptableOrUnknown(data['ash_g']!, _ashGMeta),
      );
    }
    if (data.containsKey('alcohol_g')) {
      context.handle(
        _alcoholGMeta,
        alcoholG.isAcceptableOrUnknown(data['alcohol_g']!, _alcoholGMeta),
      );
    }
    if (data.containsKey('sat_fat_g')) {
      context.handle(
        _satFatGMeta,
        satFatG.isAcceptableOrUnknown(data['sat_fat_g']!, _satFatGMeta),
      );
    }
    if (data.containsKey('mono_fat_g')) {
      context.handle(
        _monoFatGMeta,
        monoFatG.isAcceptableOrUnknown(data['mono_fat_g']!, _monoFatGMeta),
      );
    }
    if (data.containsKey('poly_fat_g')) {
      context.handle(
        _polyFatGMeta,
        polyFatG.isAcceptableOrUnknown(data['poly_fat_g']!, _polyFatGMeta),
      );
    }
    if (data.containsKey('trans_fat_g')) {
      context.handle(
        _transFatGMeta,
        transFatG.isAcceptableOrUnknown(data['trans_fat_g']!, _transFatGMeta),
      );
    }
    if (data.containsKey('cholesterol_mg')) {
      context.handle(
        _cholesterolMgMeta,
        cholesterolMg.isAcceptableOrUnknown(
          data['cholesterol_mg']!,
          _cholesterolMgMeta,
        ),
      );
    }
    if (data.containsKey('omega3_epa_g')) {
      context.handle(
        _omega3EpaGMeta,
        omega3EpaG.isAcceptableOrUnknown(
          data['omega3_epa_g']!,
          _omega3EpaGMeta,
        ),
      );
    }
    if (data.containsKey('omega3_dha_g')) {
      context.handle(
        _omega3DhaGMeta,
        omega3DhaG.isAcceptableOrUnknown(
          data['omega3_dha_g']!,
          _omega3DhaGMeta,
        ),
      );
    }
    if (data.containsKey('calcium_mg')) {
      context.handle(
        _calciumMgMeta,
        calciumMg.isAcceptableOrUnknown(data['calcium_mg']!, _calciumMgMeta),
      );
    }
    if (data.containsKey('iron_mg')) {
      context.handle(
        _ironMgMeta,
        ironMg.isAcceptableOrUnknown(data['iron_mg']!, _ironMgMeta),
      );
    }
    if (data.containsKey('magnesium_mg')) {
      context.handle(
        _magnesiumMgMeta,
        magnesiumMg.isAcceptableOrUnknown(
          data['magnesium_mg']!,
          _magnesiumMgMeta,
        ),
      );
    }
    if (data.containsKey('phosphorus_mg')) {
      context.handle(
        _phosphorusMgMeta,
        phosphorusMg.isAcceptableOrUnknown(
          data['phosphorus_mg']!,
          _phosphorusMgMeta,
        ),
      );
    }
    if (data.containsKey('potassium_mg')) {
      context.handle(
        _potassiumMgMeta,
        potassiumMg.isAcceptableOrUnknown(
          data['potassium_mg']!,
          _potassiumMgMeta,
        ),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('zinc_mg')) {
      context.handle(
        _zincMgMeta,
        zincMg.isAcceptableOrUnknown(data['zinc_mg']!, _zincMgMeta),
      );
    }
    if (data.containsKey('copper_mg')) {
      context.handle(
        _copperMgMeta,
        copperMg.isAcceptableOrUnknown(data['copper_mg']!, _copperMgMeta),
      );
    }
    if (data.containsKey('manganese_mg')) {
      context.handle(
        _manganeseMgMeta,
        manganeseMg.isAcceptableOrUnknown(
          data['manganese_mg']!,
          _manganeseMgMeta,
        ),
      );
    }
    if (data.containsKey('selenium_ug')) {
      context.handle(
        _seleniumUgMeta,
        seleniumUg.isAcceptableOrUnknown(data['selenium_ug']!, _seleniumUgMeta),
      );
    }
    if (data.containsKey('fluoride_ug')) {
      context.handle(
        _fluorideUgMeta,
        fluorideUg.isAcceptableOrUnknown(data['fluoride_ug']!, _fluorideUgMeta),
      );
    }
    if (data.containsKey('iodine_ug')) {
      context.handle(
        _iodineUgMeta,
        iodineUg.isAcceptableOrUnknown(data['iodine_ug']!, _iodineUgMeta),
      );
    }
    if (data.containsKey('vitamin_a_rae_ug')) {
      context.handle(
        _vitaminARaeUgMeta,
        vitaminARaeUg.isAcceptableOrUnknown(
          data['vitamin_a_rae_ug']!,
          _vitaminARaeUgMeta,
        ),
      );
    }
    if (data.containsKey('retinol_ug')) {
      context.handle(
        _retinolUgMeta,
        retinolUg.isAcceptableOrUnknown(data['retinol_ug']!, _retinolUgMeta),
      );
    }
    if (data.containsKey('carotene_beta_ug')) {
      context.handle(
        _caroteneBetaUgMeta,
        caroteneBetaUg.isAcceptableOrUnknown(
          data['carotene_beta_ug']!,
          _caroteneBetaUgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_c_mg')) {
      context.handle(
        _vitaminCMgMeta,
        vitaminCMg.isAcceptableOrUnknown(
          data['vitamin_c_mg']!,
          _vitaminCMgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_d_ug')) {
      context.handle(
        _vitaminDUgMeta,
        vitaminDUg.isAcceptableOrUnknown(
          data['vitamin_d_ug']!,
          _vitaminDUgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_e_mg')) {
      context.handle(
        _vitaminEMgMeta,
        vitaminEMg.isAcceptableOrUnknown(
          data['vitamin_e_mg']!,
          _vitaminEMgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_k_ug')) {
      context.handle(
        _vitaminKUgMeta,
        vitaminKUg.isAcceptableOrUnknown(
          data['vitamin_k_ug']!,
          _vitaminKUgMeta,
        ),
      );
    }
    if (data.containsKey('thiamin_mg')) {
      context.handle(
        _thiaminMgMeta,
        thiaminMg.isAcceptableOrUnknown(data['thiamin_mg']!, _thiaminMgMeta),
      );
    }
    if (data.containsKey('riboflavin_mg')) {
      context.handle(
        _riboflavinMgMeta,
        riboflavinMg.isAcceptableOrUnknown(
          data['riboflavin_mg']!,
          _riboflavinMgMeta,
        ),
      );
    }
    if (data.containsKey('niacin_mg')) {
      context.handle(
        _niacinMgMeta,
        niacinMg.isAcceptableOrUnknown(data['niacin_mg']!, _niacinMgMeta),
      );
    }
    if (data.containsKey('pantothenic_acid_mg')) {
      context.handle(
        _pantothenicAcidMgMeta,
        pantothenicAcidMg.isAcceptableOrUnknown(
          data['pantothenic_acid_mg']!,
          _pantothenicAcidMgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_b6_mg')) {
      context.handle(
        _vitaminB6MgMeta,
        vitaminB6Mg.isAcceptableOrUnknown(
          data['vitamin_b6_mg']!,
          _vitaminB6MgMeta,
        ),
      );
    }
    if (data.containsKey('folate_ug')) {
      context.handle(
        _folateUgMeta,
        folateUg.isAcceptableOrUnknown(data['folate_ug']!, _folateUgMeta),
      );
    }
    if (data.containsKey('folate_dfe_ug')) {
      context.handle(
        _folateDfeUgMeta,
        folateDfeUg.isAcceptableOrUnknown(
          data['folate_dfe_ug']!,
          _folateDfeUgMeta,
        ),
      );
    }
    if (data.containsKey('vitamin_b12_ug')) {
      context.handle(
        _vitaminB12UgMeta,
        vitaminB12Ug.isAcceptableOrUnknown(
          data['vitamin_b12_ug']!,
          _vitaminB12UgMeta,
        ),
      );
    }
    if (data.containsKey('choline_mg')) {
      context.handle(
        _cholineMgMeta,
        cholineMg.isAcceptableOrUnknown(data['choline_mg']!, _cholineMgMeta),
      );
    }
    if (data.containsKey('biotin_ug')) {
      context.handle(
        _biotinUgMeta,
        biotinUg.isAcceptableOrUnknown(data['biotin_ug']!, _biotinUgMeta),
      );
    }
    if (data.containsKey('caffeine_mg')) {
      context.handle(
        _caffeineMgMeta,
        caffeineMg.isAcceptableOrUnknown(data['caffeine_mg']!, _caffeineMgMeta),
      );
    }
    if (data.containsKey('theobromine_mg')) {
      context.handle(
        _theobromineMgMeta,
        theobromineMg.isAcceptableOrUnknown(
          data['theobromine_mg']!,
          _theobromineMgMeta,
        ),
      );
    }
    if (data.containsKey('lycopene_ug')) {
      context.handle(
        _lycopeneUgMeta,
        lycopeneUg.isAcceptableOrUnknown(data['lycopene_ug']!, _lycopeneUgMeta),
      );
    }
    if (data.containsKey('lutein_zeaxanthin_ug')) {
      context.handle(
        _luteinZeaxanthinUgMeta,
        luteinZeaxanthinUg.isAcceptableOrUnknown(
          data['lutein_zeaxanthin_ug']!,
          _luteinZeaxanthinUgMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted')) {
      context.handle(
        _deletedMeta,
        deleted.isAcceptableOrUnknown(data['deleted']!, _deletedMeta),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      ),
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}food_id'],
      ),
      customFoodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_food_id'],
      ),
      loggedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}logged_at'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      ),
      grams: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}grams'],
      )!,
      portionQty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}portion_qty'],
      ),
      portionLabel: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portion_label'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      emoji: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}emoji'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      carbG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carb_g'],
      ),
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      ),
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      ),
      starchG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}starch_g'],
      ),
      waterG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}water_g'],
      ),
      ashG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}ash_g'],
      ),
      alcoholG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}alcohol_g'],
      ),
      satFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sat_fat_g'],
      ),
      monoFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}mono_fat_g'],
      ),
      polyFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}poly_fat_g'],
      ),
      transFatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}trans_fat_g'],
      ),
      cholesterolMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}cholesterol_mg'],
      ),
      omega3EpaG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}omega3_epa_g'],
      ),
      omega3DhaG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}omega3_dha_g'],
      ),
      calciumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}calcium_mg'],
      ),
      ironMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iron_mg'],
      ),
      magnesiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}magnesium_mg'],
      ),
      phosphorusMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}phosphorus_mg'],
      ),
      potassiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}potassium_mg'],
      ),
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      ),
      zincMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}zinc_mg'],
      ),
      copperMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}copper_mg'],
      ),
      manganeseMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}manganese_mg'],
      ),
      seleniumUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}selenium_ug'],
      ),
      fluorideUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fluoride_ug'],
      ),
      iodineUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}iodine_ug'],
      ),
      vitaminARaeUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_a_rae_ug'],
      ),
      retinolUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}retinol_ug'],
      ),
      caroteneBetaUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carotene_beta_ug'],
      ),
      vitaminCMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_c_mg'],
      ),
      vitaminDUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_d_ug'],
      ),
      vitaminEMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_e_mg'],
      ),
      vitaminKUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_k_ug'],
      ),
      thiaminMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}thiamin_mg'],
      ),
      riboflavinMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}riboflavin_mg'],
      ),
      niacinMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}niacin_mg'],
      ),
      pantothenicAcidMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pantothenic_acid_mg'],
      ),
      vitaminB6Mg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_b6_mg'],
      ),
      folateUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}folate_ug'],
      ),
      folateDfeUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}folate_dfe_ug'],
      ),
      vitaminB12Ug: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}vitamin_b12_ug'],
      ),
      cholineMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}choline_mg'],
      ),
      biotinUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}biotin_ug'],
      ),
      caffeineMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}caffeine_mg'],
      ),
      theobromineMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}theobromine_mg'],
      ),
      lycopeneUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lycopene_ug'],
      ),
      luteinZeaxanthinUg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}lutein_zeaxanthin_ug'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      deleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dirty'],
      )!,
    );
  }

  @override
  LogEntries createAlias(String alias) {
    return LogEntries(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'CHECK((food_id IS NULL)<>(custom_food_id IS NULL))',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class LogEntry extends DataClass implements Insertable<LogEntry> {
  final String? id;
  final int? foodId;
  final String? customFoodId;
  final String loggedAt;
  final String? localDate;
  final double grams;
  final double? portionQty;
  final String? portionLabel;
  final String name;
  final String? emoji;
  final double? energyKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbG;
  final double? fiberG;
  final double? sugarG;
  final double? starchG;
  final double? waterG;
  final double? ashG;
  final double? alcoholG;
  final double? satFatG;
  final double? monoFatG;
  final double? polyFatG;
  final double? transFatG;
  final double? cholesterolMg;
  final double? omega3EpaG;
  final double? omega3DhaG;
  final double? calciumMg;
  final double? ironMg;
  final double? magnesiumMg;
  final double? phosphorusMg;
  final double? potassiumMg;
  final double? sodiumMg;
  final double? zincMg;
  final double? copperMg;
  final double? manganeseMg;
  final double? seleniumUg;
  final double? fluorideUg;
  final double? iodineUg;
  final double? vitaminARaeUg;
  final double? retinolUg;
  final double? caroteneBetaUg;
  final double? vitaminCMg;
  final double? vitaminDUg;
  final double? vitaminEMg;
  final double? vitaminKUg;
  final double? thiaminMg;
  final double? riboflavinMg;
  final double? niacinMg;
  final double? pantothenicAcidMg;
  final double? vitaminB6Mg;
  final double? folateUg;
  final double? folateDfeUg;
  final double? vitaminB12Ug;
  final double? cholineMg;
  final double? biotinUg;
  final double? caffeineMg;
  final double? theobromineMg;
  final double? lycopeneUg;
  final double? luteinZeaxanthinUg;
  final int updatedAt;
  final int deleted;
  final int dirty;
  const LogEntry({
    this.id,
    this.foodId,
    this.customFoodId,
    required this.loggedAt,
    this.localDate,
    required this.grams,
    this.portionQty,
    this.portionLabel,
    required this.name,
    this.emoji,
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbG,
    this.fiberG,
    this.sugarG,
    this.starchG,
    this.waterG,
    this.ashG,
    this.alcoholG,
    this.satFatG,
    this.monoFatG,
    this.polyFatG,
    this.transFatG,
    this.cholesterolMg,
    this.omega3EpaG,
    this.omega3DhaG,
    this.calciumMg,
    this.ironMg,
    this.magnesiumMg,
    this.phosphorusMg,
    this.potassiumMg,
    this.sodiumMg,
    this.zincMg,
    this.copperMg,
    this.manganeseMg,
    this.seleniumUg,
    this.fluorideUg,
    this.iodineUg,
    this.vitaminARaeUg,
    this.retinolUg,
    this.caroteneBetaUg,
    this.vitaminCMg,
    this.vitaminDUg,
    this.vitaminEMg,
    this.vitaminKUg,
    this.thiaminMg,
    this.riboflavinMg,
    this.niacinMg,
    this.pantothenicAcidMg,
    this.vitaminB6Mg,
    this.folateUg,
    this.folateDfeUg,
    this.vitaminB12Ug,
    this.cholineMg,
    this.biotinUg,
    this.caffeineMg,
    this.theobromineMg,
    this.lycopeneUg,
    this.luteinZeaxanthinUg,
    required this.updatedAt,
    required this.deleted,
    required this.dirty,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || id != null) {
      map['id'] = Variable<String>(id);
    }
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<int>(foodId);
    }
    if (!nullToAbsent || customFoodId != null) {
      map['custom_food_id'] = Variable<String>(customFoodId);
    }
    map['logged_at'] = Variable<String>(loggedAt);
    map['grams'] = Variable<double>(grams);
    if (!nullToAbsent || portionQty != null) {
      map['portion_qty'] = Variable<double>(portionQty);
    }
    if (!nullToAbsent || portionLabel != null) {
      map['portion_label'] = Variable<String>(portionLabel);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || emoji != null) {
      map['emoji'] = Variable<String>(emoji);
    }
    if (!nullToAbsent || energyKcal != null) {
      map['energy_kcal'] = Variable<double>(energyKcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    if (!nullToAbsent || carbG != null) {
      map['carb_g'] = Variable<double>(carbG);
    }
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    if (!nullToAbsent || sugarG != null) {
      map['sugar_g'] = Variable<double>(sugarG);
    }
    if (!nullToAbsent || starchG != null) {
      map['starch_g'] = Variable<double>(starchG);
    }
    if (!nullToAbsent || waterG != null) {
      map['water_g'] = Variable<double>(waterG);
    }
    if (!nullToAbsent || ashG != null) {
      map['ash_g'] = Variable<double>(ashG);
    }
    if (!nullToAbsent || alcoholG != null) {
      map['alcohol_g'] = Variable<double>(alcoholG);
    }
    if (!nullToAbsent || satFatG != null) {
      map['sat_fat_g'] = Variable<double>(satFatG);
    }
    if (!nullToAbsent || monoFatG != null) {
      map['mono_fat_g'] = Variable<double>(monoFatG);
    }
    if (!nullToAbsent || polyFatG != null) {
      map['poly_fat_g'] = Variable<double>(polyFatG);
    }
    if (!nullToAbsent || transFatG != null) {
      map['trans_fat_g'] = Variable<double>(transFatG);
    }
    if (!nullToAbsent || cholesterolMg != null) {
      map['cholesterol_mg'] = Variable<double>(cholesterolMg);
    }
    if (!nullToAbsent || omega3EpaG != null) {
      map['omega3_epa_g'] = Variable<double>(omega3EpaG);
    }
    if (!nullToAbsent || omega3DhaG != null) {
      map['omega3_dha_g'] = Variable<double>(omega3DhaG);
    }
    if (!nullToAbsent || calciumMg != null) {
      map['calcium_mg'] = Variable<double>(calciumMg);
    }
    if (!nullToAbsent || ironMg != null) {
      map['iron_mg'] = Variable<double>(ironMg);
    }
    if (!nullToAbsent || magnesiumMg != null) {
      map['magnesium_mg'] = Variable<double>(magnesiumMg);
    }
    if (!nullToAbsent || phosphorusMg != null) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg);
    }
    if (!nullToAbsent || potassiumMg != null) {
      map['potassium_mg'] = Variable<double>(potassiumMg);
    }
    if (!nullToAbsent || sodiumMg != null) {
      map['sodium_mg'] = Variable<double>(sodiumMg);
    }
    if (!nullToAbsent || zincMg != null) {
      map['zinc_mg'] = Variable<double>(zincMg);
    }
    if (!nullToAbsent || copperMg != null) {
      map['copper_mg'] = Variable<double>(copperMg);
    }
    if (!nullToAbsent || manganeseMg != null) {
      map['manganese_mg'] = Variable<double>(manganeseMg);
    }
    if (!nullToAbsent || seleniumUg != null) {
      map['selenium_ug'] = Variable<double>(seleniumUg);
    }
    if (!nullToAbsent || fluorideUg != null) {
      map['fluoride_ug'] = Variable<double>(fluorideUg);
    }
    if (!nullToAbsent || iodineUg != null) {
      map['iodine_ug'] = Variable<double>(iodineUg);
    }
    if (!nullToAbsent || vitaminARaeUg != null) {
      map['vitamin_a_rae_ug'] = Variable<double>(vitaminARaeUg);
    }
    if (!nullToAbsent || retinolUg != null) {
      map['retinol_ug'] = Variable<double>(retinolUg);
    }
    if (!nullToAbsent || caroteneBetaUg != null) {
      map['carotene_beta_ug'] = Variable<double>(caroteneBetaUg);
    }
    if (!nullToAbsent || vitaminCMg != null) {
      map['vitamin_c_mg'] = Variable<double>(vitaminCMg);
    }
    if (!nullToAbsent || vitaminDUg != null) {
      map['vitamin_d_ug'] = Variable<double>(vitaminDUg);
    }
    if (!nullToAbsent || vitaminEMg != null) {
      map['vitamin_e_mg'] = Variable<double>(vitaminEMg);
    }
    if (!nullToAbsent || vitaminKUg != null) {
      map['vitamin_k_ug'] = Variable<double>(vitaminKUg);
    }
    if (!nullToAbsent || thiaminMg != null) {
      map['thiamin_mg'] = Variable<double>(thiaminMg);
    }
    if (!nullToAbsent || riboflavinMg != null) {
      map['riboflavin_mg'] = Variable<double>(riboflavinMg);
    }
    if (!nullToAbsent || niacinMg != null) {
      map['niacin_mg'] = Variable<double>(niacinMg);
    }
    if (!nullToAbsent || pantothenicAcidMg != null) {
      map['pantothenic_acid_mg'] = Variable<double>(pantothenicAcidMg);
    }
    if (!nullToAbsent || vitaminB6Mg != null) {
      map['vitamin_b6_mg'] = Variable<double>(vitaminB6Mg);
    }
    if (!nullToAbsent || folateUg != null) {
      map['folate_ug'] = Variable<double>(folateUg);
    }
    if (!nullToAbsent || folateDfeUg != null) {
      map['folate_dfe_ug'] = Variable<double>(folateDfeUg);
    }
    if (!nullToAbsent || vitaminB12Ug != null) {
      map['vitamin_b12_ug'] = Variable<double>(vitaminB12Ug);
    }
    if (!nullToAbsent || cholineMg != null) {
      map['choline_mg'] = Variable<double>(cholineMg);
    }
    if (!nullToAbsent || biotinUg != null) {
      map['biotin_ug'] = Variable<double>(biotinUg);
    }
    if (!nullToAbsent || caffeineMg != null) {
      map['caffeine_mg'] = Variable<double>(caffeineMg);
    }
    if (!nullToAbsent || theobromineMg != null) {
      map['theobromine_mg'] = Variable<double>(theobromineMg);
    }
    if (!nullToAbsent || lycopeneUg != null) {
      map['lycopene_ug'] = Variable<double>(lycopeneUg);
    }
    if (!nullToAbsent || luteinZeaxanthinUg != null) {
      map['lutein_zeaxanthin_ug'] = Variable<double>(luteinZeaxanthinUg);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['deleted'] = Variable<int>(deleted);
    map['dirty'] = Variable<int>(dirty);
    return map;
  }

  LogEntriesCompanion toCompanion(bool nullToAbsent) {
    return LogEntriesCompanion(
      id: id == null && nullToAbsent ? const Value.absent() : Value(id),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      customFoodId: customFoodId == null && nullToAbsent
          ? const Value.absent()
          : Value(customFoodId),
      loggedAt: Value(loggedAt),
      grams: Value(grams),
      portionQty: portionQty == null && nullToAbsent
          ? const Value.absent()
          : Value(portionQty),
      portionLabel: portionLabel == null && nullToAbsent
          ? const Value.absent()
          : Value(portionLabel),
      name: Value(name),
      emoji: emoji == null && nullToAbsent
          ? const Value.absent()
          : Value(emoji),
      energyKcal: energyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(energyKcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      carbG: carbG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbG),
      fiberG: fiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG),
      sugarG: sugarG == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarG),
      starchG: starchG == null && nullToAbsent
          ? const Value.absent()
          : Value(starchG),
      waterG: waterG == null && nullToAbsent
          ? const Value.absent()
          : Value(waterG),
      ashG: ashG == null && nullToAbsent ? const Value.absent() : Value(ashG),
      alcoholG: alcoholG == null && nullToAbsent
          ? const Value.absent()
          : Value(alcoholG),
      satFatG: satFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(satFatG),
      monoFatG: monoFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(monoFatG),
      polyFatG: polyFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(polyFatG),
      transFatG: transFatG == null && nullToAbsent
          ? const Value.absent()
          : Value(transFatG),
      cholesterolMg: cholesterolMg == null && nullToAbsent
          ? const Value.absent()
          : Value(cholesterolMg),
      omega3EpaG: omega3EpaG == null && nullToAbsent
          ? const Value.absent()
          : Value(omega3EpaG),
      omega3DhaG: omega3DhaG == null && nullToAbsent
          ? const Value.absent()
          : Value(omega3DhaG),
      calciumMg: calciumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(calciumMg),
      ironMg: ironMg == null && nullToAbsent
          ? const Value.absent()
          : Value(ironMg),
      magnesiumMg: magnesiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(magnesiumMg),
      phosphorusMg: phosphorusMg == null && nullToAbsent
          ? const Value.absent()
          : Value(phosphorusMg),
      potassiumMg: potassiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(potassiumMg),
      sodiumMg: sodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg),
      zincMg: zincMg == null && nullToAbsent
          ? const Value.absent()
          : Value(zincMg),
      copperMg: copperMg == null && nullToAbsent
          ? const Value.absent()
          : Value(copperMg),
      manganeseMg: manganeseMg == null && nullToAbsent
          ? const Value.absent()
          : Value(manganeseMg),
      seleniumUg: seleniumUg == null && nullToAbsent
          ? const Value.absent()
          : Value(seleniumUg),
      fluorideUg: fluorideUg == null && nullToAbsent
          ? const Value.absent()
          : Value(fluorideUg),
      iodineUg: iodineUg == null && nullToAbsent
          ? const Value.absent()
          : Value(iodineUg),
      vitaminARaeUg: vitaminARaeUg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminARaeUg),
      retinolUg: retinolUg == null && nullToAbsent
          ? const Value.absent()
          : Value(retinolUg),
      caroteneBetaUg: caroteneBetaUg == null && nullToAbsent
          ? const Value.absent()
          : Value(caroteneBetaUg),
      vitaminCMg: vitaminCMg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminCMg),
      vitaminDUg: vitaminDUg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminDUg),
      vitaminEMg: vitaminEMg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminEMg),
      vitaminKUg: vitaminKUg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminKUg),
      thiaminMg: thiaminMg == null && nullToAbsent
          ? const Value.absent()
          : Value(thiaminMg),
      riboflavinMg: riboflavinMg == null && nullToAbsent
          ? const Value.absent()
          : Value(riboflavinMg),
      niacinMg: niacinMg == null && nullToAbsent
          ? const Value.absent()
          : Value(niacinMg),
      pantothenicAcidMg: pantothenicAcidMg == null && nullToAbsent
          ? const Value.absent()
          : Value(pantothenicAcidMg),
      vitaminB6Mg: vitaminB6Mg == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminB6Mg),
      folateUg: folateUg == null && nullToAbsent
          ? const Value.absent()
          : Value(folateUg),
      folateDfeUg: folateDfeUg == null && nullToAbsent
          ? const Value.absent()
          : Value(folateDfeUg),
      vitaminB12Ug: vitaminB12Ug == null && nullToAbsent
          ? const Value.absent()
          : Value(vitaminB12Ug),
      cholineMg: cholineMg == null && nullToAbsent
          ? const Value.absent()
          : Value(cholineMg),
      biotinUg: biotinUg == null && nullToAbsent
          ? const Value.absent()
          : Value(biotinUg),
      caffeineMg: caffeineMg == null && nullToAbsent
          ? const Value.absent()
          : Value(caffeineMg),
      theobromineMg: theobromineMg == null && nullToAbsent
          ? const Value.absent()
          : Value(theobromineMg),
      lycopeneUg: lycopeneUg == null && nullToAbsent
          ? const Value.absent()
          : Value(lycopeneUg),
      luteinZeaxanthinUg: luteinZeaxanthinUg == null && nullToAbsent
          ? const Value.absent()
          : Value(luteinZeaxanthinUg),
      updatedAt: Value(updatedAt),
      deleted: Value(deleted),
      dirty: Value(dirty),
    );
  }

  factory LogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LogEntry(
      id: serializer.fromJson<String?>(json['id']),
      foodId: serializer.fromJson<int?>(json['food_id']),
      customFoodId: serializer.fromJson<String?>(json['custom_food_id']),
      loggedAt: serializer.fromJson<String>(json['logged_at']),
      localDate: serializer.fromJson<String?>(json['local_date']),
      grams: serializer.fromJson<double>(json['grams']),
      portionQty: serializer.fromJson<double?>(json['portion_qty']),
      portionLabel: serializer.fromJson<String?>(json['portion_label']),
      name: serializer.fromJson<String>(json['name']),
      emoji: serializer.fromJson<String?>(json['emoji']),
      energyKcal: serializer.fromJson<double?>(json['energy_kcal']),
      proteinG: serializer.fromJson<double?>(json['protein_g']),
      fatG: serializer.fromJson<double?>(json['fat_g']),
      carbG: serializer.fromJson<double?>(json['carb_g']),
      fiberG: serializer.fromJson<double?>(json['fiber_g']),
      sugarG: serializer.fromJson<double?>(json['sugar_g']),
      starchG: serializer.fromJson<double?>(json['starch_g']),
      waterG: serializer.fromJson<double?>(json['water_g']),
      ashG: serializer.fromJson<double?>(json['ash_g']),
      alcoholG: serializer.fromJson<double?>(json['alcohol_g']),
      satFatG: serializer.fromJson<double?>(json['sat_fat_g']),
      monoFatG: serializer.fromJson<double?>(json['mono_fat_g']),
      polyFatG: serializer.fromJson<double?>(json['poly_fat_g']),
      transFatG: serializer.fromJson<double?>(json['trans_fat_g']),
      cholesterolMg: serializer.fromJson<double?>(json['cholesterol_mg']),
      omega3EpaG: serializer.fromJson<double?>(json['omega3_epa_g']),
      omega3DhaG: serializer.fromJson<double?>(json['omega3_dha_g']),
      calciumMg: serializer.fromJson<double?>(json['calcium_mg']),
      ironMg: serializer.fromJson<double?>(json['iron_mg']),
      magnesiumMg: serializer.fromJson<double?>(json['magnesium_mg']),
      phosphorusMg: serializer.fromJson<double?>(json['phosphorus_mg']),
      potassiumMg: serializer.fromJson<double?>(json['potassium_mg']),
      sodiumMg: serializer.fromJson<double?>(json['sodium_mg']),
      zincMg: serializer.fromJson<double?>(json['zinc_mg']),
      copperMg: serializer.fromJson<double?>(json['copper_mg']),
      manganeseMg: serializer.fromJson<double?>(json['manganese_mg']),
      seleniumUg: serializer.fromJson<double?>(json['selenium_ug']),
      fluorideUg: serializer.fromJson<double?>(json['fluoride_ug']),
      iodineUg: serializer.fromJson<double?>(json['iodine_ug']),
      vitaminARaeUg: serializer.fromJson<double?>(json['vitamin_a_rae_ug']),
      retinolUg: serializer.fromJson<double?>(json['retinol_ug']),
      caroteneBetaUg: serializer.fromJson<double?>(json['carotene_beta_ug']),
      vitaminCMg: serializer.fromJson<double?>(json['vitamin_c_mg']),
      vitaminDUg: serializer.fromJson<double?>(json['vitamin_d_ug']),
      vitaminEMg: serializer.fromJson<double?>(json['vitamin_e_mg']),
      vitaminKUg: serializer.fromJson<double?>(json['vitamin_k_ug']),
      thiaminMg: serializer.fromJson<double?>(json['thiamin_mg']),
      riboflavinMg: serializer.fromJson<double?>(json['riboflavin_mg']),
      niacinMg: serializer.fromJson<double?>(json['niacin_mg']),
      pantothenicAcidMg: serializer.fromJson<double?>(
        json['pantothenic_acid_mg'],
      ),
      vitaminB6Mg: serializer.fromJson<double?>(json['vitamin_b6_mg']),
      folateUg: serializer.fromJson<double?>(json['folate_ug']),
      folateDfeUg: serializer.fromJson<double?>(json['folate_dfe_ug']),
      vitaminB12Ug: serializer.fromJson<double?>(json['vitamin_b12_ug']),
      cholineMg: serializer.fromJson<double?>(json['choline_mg']),
      biotinUg: serializer.fromJson<double?>(json['biotin_ug']),
      caffeineMg: serializer.fromJson<double?>(json['caffeine_mg']),
      theobromineMg: serializer.fromJson<double?>(json['theobromine_mg']),
      lycopeneUg: serializer.fromJson<double?>(json['lycopene_ug']),
      luteinZeaxanthinUg: serializer.fromJson<double?>(
        json['lutein_zeaxanthin_ug'],
      ),
      updatedAt: serializer.fromJson<int>(json['updated_at']),
      deleted: serializer.fromJson<int>(json['deleted']),
      dirty: serializer.fromJson<int>(json['dirty']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String?>(id),
      'food_id': serializer.toJson<int?>(foodId),
      'custom_food_id': serializer.toJson<String?>(customFoodId),
      'logged_at': serializer.toJson<String>(loggedAt),
      'local_date': serializer.toJson<String?>(localDate),
      'grams': serializer.toJson<double>(grams),
      'portion_qty': serializer.toJson<double?>(portionQty),
      'portion_label': serializer.toJson<String?>(portionLabel),
      'name': serializer.toJson<String>(name),
      'emoji': serializer.toJson<String?>(emoji),
      'energy_kcal': serializer.toJson<double?>(energyKcal),
      'protein_g': serializer.toJson<double?>(proteinG),
      'fat_g': serializer.toJson<double?>(fatG),
      'carb_g': serializer.toJson<double?>(carbG),
      'fiber_g': serializer.toJson<double?>(fiberG),
      'sugar_g': serializer.toJson<double?>(sugarG),
      'starch_g': serializer.toJson<double?>(starchG),
      'water_g': serializer.toJson<double?>(waterG),
      'ash_g': serializer.toJson<double?>(ashG),
      'alcohol_g': serializer.toJson<double?>(alcoholG),
      'sat_fat_g': serializer.toJson<double?>(satFatG),
      'mono_fat_g': serializer.toJson<double?>(monoFatG),
      'poly_fat_g': serializer.toJson<double?>(polyFatG),
      'trans_fat_g': serializer.toJson<double?>(transFatG),
      'cholesterol_mg': serializer.toJson<double?>(cholesterolMg),
      'omega3_epa_g': serializer.toJson<double?>(omega3EpaG),
      'omega3_dha_g': serializer.toJson<double?>(omega3DhaG),
      'calcium_mg': serializer.toJson<double?>(calciumMg),
      'iron_mg': serializer.toJson<double?>(ironMg),
      'magnesium_mg': serializer.toJson<double?>(magnesiumMg),
      'phosphorus_mg': serializer.toJson<double?>(phosphorusMg),
      'potassium_mg': serializer.toJson<double?>(potassiumMg),
      'sodium_mg': serializer.toJson<double?>(sodiumMg),
      'zinc_mg': serializer.toJson<double?>(zincMg),
      'copper_mg': serializer.toJson<double?>(copperMg),
      'manganese_mg': serializer.toJson<double?>(manganeseMg),
      'selenium_ug': serializer.toJson<double?>(seleniumUg),
      'fluoride_ug': serializer.toJson<double?>(fluorideUg),
      'iodine_ug': serializer.toJson<double?>(iodineUg),
      'vitamin_a_rae_ug': serializer.toJson<double?>(vitaminARaeUg),
      'retinol_ug': serializer.toJson<double?>(retinolUg),
      'carotene_beta_ug': serializer.toJson<double?>(caroteneBetaUg),
      'vitamin_c_mg': serializer.toJson<double?>(vitaminCMg),
      'vitamin_d_ug': serializer.toJson<double?>(vitaminDUg),
      'vitamin_e_mg': serializer.toJson<double?>(vitaminEMg),
      'vitamin_k_ug': serializer.toJson<double?>(vitaminKUg),
      'thiamin_mg': serializer.toJson<double?>(thiaminMg),
      'riboflavin_mg': serializer.toJson<double?>(riboflavinMg),
      'niacin_mg': serializer.toJson<double?>(niacinMg),
      'pantothenic_acid_mg': serializer.toJson<double?>(pantothenicAcidMg),
      'vitamin_b6_mg': serializer.toJson<double?>(vitaminB6Mg),
      'folate_ug': serializer.toJson<double?>(folateUg),
      'folate_dfe_ug': serializer.toJson<double?>(folateDfeUg),
      'vitamin_b12_ug': serializer.toJson<double?>(vitaminB12Ug),
      'choline_mg': serializer.toJson<double?>(cholineMg),
      'biotin_ug': serializer.toJson<double?>(biotinUg),
      'caffeine_mg': serializer.toJson<double?>(caffeineMg),
      'theobromine_mg': serializer.toJson<double?>(theobromineMg),
      'lycopene_ug': serializer.toJson<double?>(lycopeneUg),
      'lutein_zeaxanthin_ug': serializer.toJson<double?>(luteinZeaxanthinUg),
      'updated_at': serializer.toJson<int>(updatedAt),
      'deleted': serializer.toJson<int>(deleted),
      'dirty': serializer.toJson<int>(dirty),
    };
  }

  LogEntry copyWith({
    Value<String?> id = const Value.absent(),
    Value<int?> foodId = const Value.absent(),
    Value<String?> customFoodId = const Value.absent(),
    String? loggedAt,
    Value<String?> localDate = const Value.absent(),
    double? grams,
    Value<double?> portionQty = const Value.absent(),
    Value<String?> portionLabel = const Value.absent(),
    String? name,
    Value<String?> emoji = const Value.absent(),
    Value<double?> energyKcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    Value<double?> carbG = const Value.absent(),
    Value<double?> fiberG = const Value.absent(),
    Value<double?> sugarG = const Value.absent(),
    Value<double?> starchG = const Value.absent(),
    Value<double?> waterG = const Value.absent(),
    Value<double?> ashG = const Value.absent(),
    Value<double?> alcoholG = const Value.absent(),
    Value<double?> satFatG = const Value.absent(),
    Value<double?> monoFatG = const Value.absent(),
    Value<double?> polyFatG = const Value.absent(),
    Value<double?> transFatG = const Value.absent(),
    Value<double?> cholesterolMg = const Value.absent(),
    Value<double?> omega3EpaG = const Value.absent(),
    Value<double?> omega3DhaG = const Value.absent(),
    Value<double?> calciumMg = const Value.absent(),
    Value<double?> ironMg = const Value.absent(),
    Value<double?> magnesiumMg = const Value.absent(),
    Value<double?> phosphorusMg = const Value.absent(),
    Value<double?> potassiumMg = const Value.absent(),
    Value<double?> sodiumMg = const Value.absent(),
    Value<double?> zincMg = const Value.absent(),
    Value<double?> copperMg = const Value.absent(),
    Value<double?> manganeseMg = const Value.absent(),
    Value<double?> seleniumUg = const Value.absent(),
    Value<double?> fluorideUg = const Value.absent(),
    Value<double?> iodineUg = const Value.absent(),
    Value<double?> vitaminARaeUg = const Value.absent(),
    Value<double?> retinolUg = const Value.absent(),
    Value<double?> caroteneBetaUg = const Value.absent(),
    Value<double?> vitaminCMg = const Value.absent(),
    Value<double?> vitaminDUg = const Value.absent(),
    Value<double?> vitaminEMg = const Value.absent(),
    Value<double?> vitaminKUg = const Value.absent(),
    Value<double?> thiaminMg = const Value.absent(),
    Value<double?> riboflavinMg = const Value.absent(),
    Value<double?> niacinMg = const Value.absent(),
    Value<double?> pantothenicAcidMg = const Value.absent(),
    Value<double?> vitaminB6Mg = const Value.absent(),
    Value<double?> folateUg = const Value.absent(),
    Value<double?> folateDfeUg = const Value.absent(),
    Value<double?> vitaminB12Ug = const Value.absent(),
    Value<double?> cholineMg = const Value.absent(),
    Value<double?> biotinUg = const Value.absent(),
    Value<double?> caffeineMg = const Value.absent(),
    Value<double?> theobromineMg = const Value.absent(),
    Value<double?> lycopeneUg = const Value.absent(),
    Value<double?> luteinZeaxanthinUg = const Value.absent(),
    int? updatedAt,
    int? deleted,
    int? dirty,
  }) => LogEntry(
    id: id.present ? id.value : this.id,
    foodId: foodId.present ? foodId.value : this.foodId,
    customFoodId: customFoodId.present ? customFoodId.value : this.customFoodId,
    loggedAt: loggedAt ?? this.loggedAt,
    localDate: localDate.present ? localDate.value : this.localDate,
    grams: grams ?? this.grams,
    portionQty: portionQty.present ? portionQty.value : this.portionQty,
    portionLabel: portionLabel.present ? portionLabel.value : this.portionLabel,
    name: name ?? this.name,
    emoji: emoji.present ? emoji.value : this.emoji,
    energyKcal: energyKcal.present ? energyKcal.value : this.energyKcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    fatG: fatG.present ? fatG.value : this.fatG,
    carbG: carbG.present ? carbG.value : this.carbG,
    fiberG: fiberG.present ? fiberG.value : this.fiberG,
    sugarG: sugarG.present ? sugarG.value : this.sugarG,
    starchG: starchG.present ? starchG.value : this.starchG,
    waterG: waterG.present ? waterG.value : this.waterG,
    ashG: ashG.present ? ashG.value : this.ashG,
    alcoholG: alcoholG.present ? alcoholG.value : this.alcoholG,
    satFatG: satFatG.present ? satFatG.value : this.satFatG,
    monoFatG: monoFatG.present ? monoFatG.value : this.monoFatG,
    polyFatG: polyFatG.present ? polyFatG.value : this.polyFatG,
    transFatG: transFatG.present ? transFatG.value : this.transFatG,
    cholesterolMg: cholesterolMg.present
        ? cholesterolMg.value
        : this.cholesterolMg,
    omega3EpaG: omega3EpaG.present ? omega3EpaG.value : this.omega3EpaG,
    omega3DhaG: omega3DhaG.present ? omega3DhaG.value : this.omega3DhaG,
    calciumMg: calciumMg.present ? calciumMg.value : this.calciumMg,
    ironMg: ironMg.present ? ironMg.value : this.ironMg,
    magnesiumMg: magnesiumMg.present ? magnesiumMg.value : this.magnesiumMg,
    phosphorusMg: phosphorusMg.present ? phosphorusMg.value : this.phosphorusMg,
    potassiumMg: potassiumMg.present ? potassiumMg.value : this.potassiumMg,
    sodiumMg: sodiumMg.present ? sodiumMg.value : this.sodiumMg,
    zincMg: zincMg.present ? zincMg.value : this.zincMg,
    copperMg: copperMg.present ? copperMg.value : this.copperMg,
    manganeseMg: manganeseMg.present ? manganeseMg.value : this.manganeseMg,
    seleniumUg: seleniumUg.present ? seleniumUg.value : this.seleniumUg,
    fluorideUg: fluorideUg.present ? fluorideUg.value : this.fluorideUg,
    iodineUg: iodineUg.present ? iodineUg.value : this.iodineUg,
    vitaminARaeUg: vitaminARaeUg.present
        ? vitaminARaeUg.value
        : this.vitaminARaeUg,
    retinolUg: retinolUg.present ? retinolUg.value : this.retinolUg,
    caroteneBetaUg: caroteneBetaUg.present
        ? caroteneBetaUg.value
        : this.caroteneBetaUg,
    vitaminCMg: vitaminCMg.present ? vitaminCMg.value : this.vitaminCMg,
    vitaminDUg: vitaminDUg.present ? vitaminDUg.value : this.vitaminDUg,
    vitaminEMg: vitaminEMg.present ? vitaminEMg.value : this.vitaminEMg,
    vitaminKUg: vitaminKUg.present ? vitaminKUg.value : this.vitaminKUg,
    thiaminMg: thiaminMg.present ? thiaminMg.value : this.thiaminMg,
    riboflavinMg: riboflavinMg.present ? riboflavinMg.value : this.riboflavinMg,
    niacinMg: niacinMg.present ? niacinMg.value : this.niacinMg,
    pantothenicAcidMg: pantothenicAcidMg.present
        ? pantothenicAcidMg.value
        : this.pantothenicAcidMg,
    vitaminB6Mg: vitaminB6Mg.present ? vitaminB6Mg.value : this.vitaminB6Mg,
    folateUg: folateUg.present ? folateUg.value : this.folateUg,
    folateDfeUg: folateDfeUg.present ? folateDfeUg.value : this.folateDfeUg,
    vitaminB12Ug: vitaminB12Ug.present ? vitaminB12Ug.value : this.vitaminB12Ug,
    cholineMg: cholineMg.present ? cholineMg.value : this.cholineMg,
    biotinUg: biotinUg.present ? biotinUg.value : this.biotinUg,
    caffeineMg: caffeineMg.present ? caffeineMg.value : this.caffeineMg,
    theobromineMg: theobromineMg.present
        ? theobromineMg.value
        : this.theobromineMg,
    lycopeneUg: lycopeneUg.present ? lycopeneUg.value : this.lycopeneUg,
    luteinZeaxanthinUg: luteinZeaxanthinUg.present
        ? luteinZeaxanthinUg.value
        : this.luteinZeaxanthinUg,
    updatedAt: updatedAt ?? this.updatedAt,
    deleted: deleted ?? this.deleted,
    dirty: dirty ?? this.dirty,
  );
  @override
  String toString() {
    return (StringBuffer('LogEntry(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('localDate: $localDate, ')
          ..write('grams: $grams, ')
          ..write('portionQty: $portionQty, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('starchG: $starchG, ')
          ..write('waterG: $waterG, ')
          ..write('ashG: $ashG, ')
          ..write('alcoholG: $alcoholG, ')
          ..write('satFatG: $satFatG, ')
          ..write('monoFatG: $monoFatG, ')
          ..write('polyFatG: $polyFatG, ')
          ..write('transFatG: $transFatG, ')
          ..write('cholesterolMg: $cholesterolMg, ')
          ..write('omega3EpaG: $omega3EpaG, ')
          ..write('omega3DhaG: $omega3DhaG, ')
          ..write('calciumMg: $calciumMg, ')
          ..write('ironMg: $ironMg, ')
          ..write('magnesiumMg: $magnesiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('zincMg: $zincMg, ')
          ..write('copperMg: $copperMg, ')
          ..write('manganeseMg: $manganeseMg, ')
          ..write('seleniumUg: $seleniumUg, ')
          ..write('fluorideUg: $fluorideUg, ')
          ..write('iodineUg: $iodineUg, ')
          ..write('vitaminARaeUg: $vitaminARaeUg, ')
          ..write('retinolUg: $retinolUg, ')
          ..write('caroteneBetaUg: $caroteneBetaUg, ')
          ..write('vitaminCMg: $vitaminCMg, ')
          ..write('vitaminDUg: $vitaminDUg, ')
          ..write('vitaminEMg: $vitaminEMg, ')
          ..write('vitaminKUg: $vitaminKUg, ')
          ..write('thiaminMg: $thiaminMg, ')
          ..write('riboflavinMg: $riboflavinMg, ')
          ..write('niacinMg: $niacinMg, ')
          ..write('pantothenicAcidMg: $pantothenicAcidMg, ')
          ..write('vitaminB6Mg: $vitaminB6Mg, ')
          ..write('folateUg: $folateUg, ')
          ..write('folateDfeUg: $folateDfeUg, ')
          ..write('vitaminB12Ug: $vitaminB12Ug, ')
          ..write('cholineMg: $cholineMg, ')
          ..write('biotinUg: $biotinUg, ')
          ..write('caffeineMg: $caffeineMg, ')
          ..write('theobromineMg: $theobromineMg, ')
          ..write('lycopeneUg: $lycopeneUg, ')
          ..write('luteinZeaxanthinUg: $luteinZeaxanthinUg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('dirty: $dirty')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    foodId,
    customFoodId,
    loggedAt,
    localDate,
    grams,
    portionQty,
    portionLabel,
    name,
    emoji,
    energyKcal,
    proteinG,
    fatG,
    carbG,
    fiberG,
    sugarG,
    starchG,
    waterG,
    ashG,
    alcoholG,
    satFatG,
    monoFatG,
    polyFatG,
    transFatG,
    cholesterolMg,
    omega3EpaG,
    omega3DhaG,
    calciumMg,
    ironMg,
    magnesiumMg,
    phosphorusMg,
    potassiumMg,
    sodiumMg,
    zincMg,
    copperMg,
    manganeseMg,
    seleniumUg,
    fluorideUg,
    iodineUg,
    vitaminARaeUg,
    retinolUg,
    caroteneBetaUg,
    vitaminCMg,
    vitaminDUg,
    vitaminEMg,
    vitaminKUg,
    thiaminMg,
    riboflavinMg,
    niacinMg,
    pantothenicAcidMg,
    vitaminB6Mg,
    folateUg,
    folateDfeUg,
    vitaminB12Ug,
    cholineMg,
    biotinUg,
    caffeineMg,
    theobromineMg,
    lycopeneUg,
    luteinZeaxanthinUg,
    updatedAt,
    deleted,
    dirty,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LogEntry &&
          other.id == this.id &&
          other.foodId == this.foodId &&
          other.customFoodId == this.customFoodId &&
          other.loggedAt == this.loggedAt &&
          other.localDate == this.localDate &&
          other.grams == this.grams &&
          other.portionQty == this.portionQty &&
          other.portionLabel == this.portionLabel &&
          other.name == this.name &&
          other.emoji == this.emoji &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.fatG == this.fatG &&
          other.carbG == this.carbG &&
          other.fiberG == this.fiberG &&
          other.sugarG == this.sugarG &&
          other.starchG == this.starchG &&
          other.waterG == this.waterG &&
          other.ashG == this.ashG &&
          other.alcoholG == this.alcoholG &&
          other.satFatG == this.satFatG &&
          other.monoFatG == this.monoFatG &&
          other.polyFatG == this.polyFatG &&
          other.transFatG == this.transFatG &&
          other.cholesterolMg == this.cholesterolMg &&
          other.omega3EpaG == this.omega3EpaG &&
          other.omega3DhaG == this.omega3DhaG &&
          other.calciumMg == this.calciumMg &&
          other.ironMg == this.ironMg &&
          other.magnesiumMg == this.magnesiumMg &&
          other.phosphorusMg == this.phosphorusMg &&
          other.potassiumMg == this.potassiumMg &&
          other.sodiumMg == this.sodiumMg &&
          other.zincMg == this.zincMg &&
          other.copperMg == this.copperMg &&
          other.manganeseMg == this.manganeseMg &&
          other.seleniumUg == this.seleniumUg &&
          other.fluorideUg == this.fluorideUg &&
          other.iodineUg == this.iodineUg &&
          other.vitaminARaeUg == this.vitaminARaeUg &&
          other.retinolUg == this.retinolUg &&
          other.caroteneBetaUg == this.caroteneBetaUg &&
          other.vitaminCMg == this.vitaminCMg &&
          other.vitaminDUg == this.vitaminDUg &&
          other.vitaminEMg == this.vitaminEMg &&
          other.vitaminKUg == this.vitaminKUg &&
          other.thiaminMg == this.thiaminMg &&
          other.riboflavinMg == this.riboflavinMg &&
          other.niacinMg == this.niacinMg &&
          other.pantothenicAcidMg == this.pantothenicAcidMg &&
          other.vitaminB6Mg == this.vitaminB6Mg &&
          other.folateUg == this.folateUg &&
          other.folateDfeUg == this.folateDfeUg &&
          other.vitaminB12Ug == this.vitaminB12Ug &&
          other.cholineMg == this.cholineMg &&
          other.biotinUg == this.biotinUg &&
          other.caffeineMg == this.caffeineMg &&
          other.theobromineMg == this.theobromineMg &&
          other.lycopeneUg == this.lycopeneUg &&
          other.luteinZeaxanthinUg == this.luteinZeaxanthinUg &&
          other.updatedAt == this.updatedAt &&
          other.deleted == this.deleted &&
          other.dirty == this.dirty);
}

class LogEntriesCompanion extends UpdateCompanion<LogEntry> {
  final Value<String?> id;
  final Value<int?> foodId;
  final Value<String?> customFoodId;
  final Value<String> loggedAt;
  final Value<double> grams;
  final Value<double?> portionQty;
  final Value<String?> portionLabel;
  final Value<String> name;
  final Value<String?> emoji;
  final Value<double?> energyKcal;
  final Value<double?> proteinG;
  final Value<double?> fatG;
  final Value<double?> carbG;
  final Value<double?> fiberG;
  final Value<double?> sugarG;
  final Value<double?> starchG;
  final Value<double?> waterG;
  final Value<double?> ashG;
  final Value<double?> alcoholG;
  final Value<double?> satFatG;
  final Value<double?> monoFatG;
  final Value<double?> polyFatG;
  final Value<double?> transFatG;
  final Value<double?> cholesterolMg;
  final Value<double?> omega3EpaG;
  final Value<double?> omega3DhaG;
  final Value<double?> calciumMg;
  final Value<double?> ironMg;
  final Value<double?> magnesiumMg;
  final Value<double?> phosphorusMg;
  final Value<double?> potassiumMg;
  final Value<double?> sodiumMg;
  final Value<double?> zincMg;
  final Value<double?> copperMg;
  final Value<double?> manganeseMg;
  final Value<double?> seleniumUg;
  final Value<double?> fluorideUg;
  final Value<double?> iodineUg;
  final Value<double?> vitaminARaeUg;
  final Value<double?> retinolUg;
  final Value<double?> caroteneBetaUg;
  final Value<double?> vitaminCMg;
  final Value<double?> vitaminDUg;
  final Value<double?> vitaminEMg;
  final Value<double?> vitaminKUg;
  final Value<double?> thiaminMg;
  final Value<double?> riboflavinMg;
  final Value<double?> niacinMg;
  final Value<double?> pantothenicAcidMg;
  final Value<double?> vitaminB6Mg;
  final Value<double?> folateUg;
  final Value<double?> folateDfeUg;
  final Value<double?> vitaminB12Ug;
  final Value<double?> cholineMg;
  final Value<double?> biotinUg;
  final Value<double?> caffeineMg;
  final Value<double?> theobromineMg;
  final Value<double?> lycopeneUg;
  final Value<double?> luteinZeaxanthinUg;
  final Value<int> updatedAt;
  final Value<int> deleted;
  final Value<int> dirty;
  final Value<int> rowid;
  const LogEntriesCompanion({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    this.loggedAt = const Value.absent(),
    this.grams = const Value.absent(),
    this.portionQty = const Value.absent(),
    this.portionLabel = const Value.absent(),
    this.name = const Value.absent(),
    this.emoji = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.starchG = const Value.absent(),
    this.waterG = const Value.absent(),
    this.ashG = const Value.absent(),
    this.alcoholG = const Value.absent(),
    this.satFatG = const Value.absent(),
    this.monoFatG = const Value.absent(),
    this.polyFatG = const Value.absent(),
    this.transFatG = const Value.absent(),
    this.cholesterolMg = const Value.absent(),
    this.omega3EpaG = const Value.absent(),
    this.omega3DhaG = const Value.absent(),
    this.calciumMg = const Value.absent(),
    this.ironMg = const Value.absent(),
    this.magnesiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.zincMg = const Value.absent(),
    this.copperMg = const Value.absent(),
    this.manganeseMg = const Value.absent(),
    this.seleniumUg = const Value.absent(),
    this.fluorideUg = const Value.absent(),
    this.iodineUg = const Value.absent(),
    this.vitaminARaeUg = const Value.absent(),
    this.retinolUg = const Value.absent(),
    this.caroteneBetaUg = const Value.absent(),
    this.vitaminCMg = const Value.absent(),
    this.vitaminDUg = const Value.absent(),
    this.vitaminEMg = const Value.absent(),
    this.vitaminKUg = const Value.absent(),
    this.thiaminMg = const Value.absent(),
    this.riboflavinMg = const Value.absent(),
    this.niacinMg = const Value.absent(),
    this.pantothenicAcidMg = const Value.absent(),
    this.vitaminB6Mg = const Value.absent(),
    this.folateUg = const Value.absent(),
    this.folateDfeUg = const Value.absent(),
    this.vitaminB12Ug = const Value.absent(),
    this.cholineMg = const Value.absent(),
    this.biotinUg = const Value.absent(),
    this.caffeineMg = const Value.absent(),
    this.theobromineMg = const Value.absent(),
    this.lycopeneUg = const Value.absent(),
    this.luteinZeaxanthinUg = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LogEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.foodId = const Value.absent(),
    this.customFoodId = const Value.absent(),
    required String loggedAt,
    required double grams,
    this.portionQty = const Value.absent(),
    this.portionLabel = const Value.absent(),
    required String name,
    this.emoji = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.carbG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.starchG = const Value.absent(),
    this.waterG = const Value.absent(),
    this.ashG = const Value.absent(),
    this.alcoholG = const Value.absent(),
    this.satFatG = const Value.absent(),
    this.monoFatG = const Value.absent(),
    this.polyFatG = const Value.absent(),
    this.transFatG = const Value.absent(),
    this.cholesterolMg = const Value.absent(),
    this.omega3EpaG = const Value.absent(),
    this.omega3DhaG = const Value.absent(),
    this.calciumMg = const Value.absent(),
    this.ironMg = const Value.absent(),
    this.magnesiumMg = const Value.absent(),
    this.phosphorusMg = const Value.absent(),
    this.potassiumMg = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.zincMg = const Value.absent(),
    this.copperMg = const Value.absent(),
    this.manganeseMg = const Value.absent(),
    this.seleniumUg = const Value.absent(),
    this.fluorideUg = const Value.absent(),
    this.iodineUg = const Value.absent(),
    this.vitaminARaeUg = const Value.absent(),
    this.retinolUg = const Value.absent(),
    this.caroteneBetaUg = const Value.absent(),
    this.vitaminCMg = const Value.absent(),
    this.vitaminDUg = const Value.absent(),
    this.vitaminEMg = const Value.absent(),
    this.vitaminKUg = const Value.absent(),
    this.thiaminMg = const Value.absent(),
    this.riboflavinMg = const Value.absent(),
    this.niacinMg = const Value.absent(),
    this.pantothenicAcidMg = const Value.absent(),
    this.vitaminB6Mg = const Value.absent(),
    this.folateUg = const Value.absent(),
    this.folateDfeUg = const Value.absent(),
    this.vitaminB12Ug = const Value.absent(),
    this.cholineMg = const Value.absent(),
    this.biotinUg = const Value.absent(),
    this.caffeineMg = const Value.absent(),
    this.theobromineMg = const Value.absent(),
    this.lycopeneUg = const Value.absent(),
    this.luteinZeaxanthinUg = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deleted = const Value.absent(),
    this.dirty = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : loggedAt = Value(loggedAt),
       grams = Value(grams),
       name = Value(name);
  static Insertable<LogEntry> custom({
    Expression<String>? id,
    Expression<int>? foodId,
    Expression<String>? customFoodId,
    Expression<String>? loggedAt,
    Expression<double>? grams,
    Expression<double>? portionQty,
    Expression<String>? portionLabel,
    Expression<String>? name,
    Expression<String>? emoji,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? fatG,
    Expression<double>? carbG,
    Expression<double>? fiberG,
    Expression<double>? sugarG,
    Expression<double>? starchG,
    Expression<double>? waterG,
    Expression<double>? ashG,
    Expression<double>? alcoholG,
    Expression<double>? satFatG,
    Expression<double>? monoFatG,
    Expression<double>? polyFatG,
    Expression<double>? transFatG,
    Expression<double>? cholesterolMg,
    Expression<double>? omega3EpaG,
    Expression<double>? omega3DhaG,
    Expression<double>? calciumMg,
    Expression<double>? ironMg,
    Expression<double>? magnesiumMg,
    Expression<double>? phosphorusMg,
    Expression<double>? potassiumMg,
    Expression<double>? sodiumMg,
    Expression<double>? zincMg,
    Expression<double>? copperMg,
    Expression<double>? manganeseMg,
    Expression<double>? seleniumUg,
    Expression<double>? fluorideUg,
    Expression<double>? iodineUg,
    Expression<double>? vitaminARaeUg,
    Expression<double>? retinolUg,
    Expression<double>? caroteneBetaUg,
    Expression<double>? vitaminCMg,
    Expression<double>? vitaminDUg,
    Expression<double>? vitaminEMg,
    Expression<double>? vitaminKUg,
    Expression<double>? thiaminMg,
    Expression<double>? riboflavinMg,
    Expression<double>? niacinMg,
    Expression<double>? pantothenicAcidMg,
    Expression<double>? vitaminB6Mg,
    Expression<double>? folateUg,
    Expression<double>? folateDfeUg,
    Expression<double>? vitaminB12Ug,
    Expression<double>? cholineMg,
    Expression<double>? biotinUg,
    Expression<double>? caffeineMg,
    Expression<double>? theobromineMg,
    Expression<double>? lycopeneUg,
    Expression<double>? luteinZeaxanthinUg,
    Expression<int>? updatedAt,
    Expression<int>? deleted,
    Expression<int>? dirty,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (foodId != null) 'food_id': foodId,
      if (customFoodId != null) 'custom_food_id': customFoodId,
      if (loggedAt != null) 'logged_at': loggedAt,
      if (grams != null) 'grams': grams,
      if (portionQty != null) 'portion_qty': portionQty,
      if (portionLabel != null) 'portion_label': portionLabel,
      if (name != null) 'name': name,
      if (emoji != null) 'emoji': emoji,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (fatG != null) 'fat_g': fatG,
      if (carbG != null) 'carb_g': carbG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (starchG != null) 'starch_g': starchG,
      if (waterG != null) 'water_g': waterG,
      if (ashG != null) 'ash_g': ashG,
      if (alcoholG != null) 'alcohol_g': alcoholG,
      if (satFatG != null) 'sat_fat_g': satFatG,
      if (monoFatG != null) 'mono_fat_g': monoFatG,
      if (polyFatG != null) 'poly_fat_g': polyFatG,
      if (transFatG != null) 'trans_fat_g': transFatG,
      if (cholesterolMg != null) 'cholesterol_mg': cholesterolMg,
      if (omega3EpaG != null) 'omega3_epa_g': omega3EpaG,
      if (omega3DhaG != null) 'omega3_dha_g': omega3DhaG,
      if (calciumMg != null) 'calcium_mg': calciumMg,
      if (ironMg != null) 'iron_mg': ironMg,
      if (magnesiumMg != null) 'magnesium_mg': magnesiumMg,
      if (phosphorusMg != null) 'phosphorus_mg': phosphorusMg,
      if (potassiumMg != null) 'potassium_mg': potassiumMg,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (zincMg != null) 'zinc_mg': zincMg,
      if (copperMg != null) 'copper_mg': copperMg,
      if (manganeseMg != null) 'manganese_mg': manganeseMg,
      if (seleniumUg != null) 'selenium_ug': seleniumUg,
      if (fluorideUg != null) 'fluoride_ug': fluorideUg,
      if (iodineUg != null) 'iodine_ug': iodineUg,
      if (vitaminARaeUg != null) 'vitamin_a_rae_ug': vitaminARaeUg,
      if (retinolUg != null) 'retinol_ug': retinolUg,
      if (caroteneBetaUg != null) 'carotene_beta_ug': caroteneBetaUg,
      if (vitaminCMg != null) 'vitamin_c_mg': vitaminCMg,
      if (vitaminDUg != null) 'vitamin_d_ug': vitaminDUg,
      if (vitaminEMg != null) 'vitamin_e_mg': vitaminEMg,
      if (vitaminKUg != null) 'vitamin_k_ug': vitaminKUg,
      if (thiaminMg != null) 'thiamin_mg': thiaminMg,
      if (riboflavinMg != null) 'riboflavin_mg': riboflavinMg,
      if (niacinMg != null) 'niacin_mg': niacinMg,
      if (pantothenicAcidMg != null) 'pantothenic_acid_mg': pantothenicAcidMg,
      if (vitaminB6Mg != null) 'vitamin_b6_mg': vitaminB6Mg,
      if (folateUg != null) 'folate_ug': folateUg,
      if (folateDfeUg != null) 'folate_dfe_ug': folateDfeUg,
      if (vitaminB12Ug != null) 'vitamin_b12_ug': vitaminB12Ug,
      if (cholineMg != null) 'choline_mg': cholineMg,
      if (biotinUg != null) 'biotin_ug': biotinUg,
      if (caffeineMg != null) 'caffeine_mg': caffeineMg,
      if (theobromineMg != null) 'theobromine_mg': theobromineMg,
      if (lycopeneUg != null) 'lycopene_ug': lycopeneUg,
      if (luteinZeaxanthinUg != null)
        'lutein_zeaxanthin_ug': luteinZeaxanthinUg,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deleted != null) 'deleted': deleted,
      if (dirty != null) 'dirty': dirty,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LogEntriesCompanion copyWith({
    Value<String?>? id,
    Value<int?>? foodId,
    Value<String?>? customFoodId,
    Value<String>? loggedAt,
    Value<double>? grams,
    Value<double?>? portionQty,
    Value<String?>? portionLabel,
    Value<String>? name,
    Value<String?>? emoji,
    Value<double?>? energyKcal,
    Value<double?>? proteinG,
    Value<double?>? fatG,
    Value<double?>? carbG,
    Value<double?>? fiberG,
    Value<double?>? sugarG,
    Value<double?>? starchG,
    Value<double?>? waterG,
    Value<double?>? ashG,
    Value<double?>? alcoholG,
    Value<double?>? satFatG,
    Value<double?>? monoFatG,
    Value<double?>? polyFatG,
    Value<double?>? transFatG,
    Value<double?>? cholesterolMg,
    Value<double?>? omega3EpaG,
    Value<double?>? omega3DhaG,
    Value<double?>? calciumMg,
    Value<double?>? ironMg,
    Value<double?>? magnesiumMg,
    Value<double?>? phosphorusMg,
    Value<double?>? potassiumMg,
    Value<double?>? sodiumMg,
    Value<double?>? zincMg,
    Value<double?>? copperMg,
    Value<double?>? manganeseMg,
    Value<double?>? seleniumUg,
    Value<double?>? fluorideUg,
    Value<double?>? iodineUg,
    Value<double?>? vitaminARaeUg,
    Value<double?>? retinolUg,
    Value<double?>? caroteneBetaUg,
    Value<double?>? vitaminCMg,
    Value<double?>? vitaminDUg,
    Value<double?>? vitaminEMg,
    Value<double?>? vitaminKUg,
    Value<double?>? thiaminMg,
    Value<double?>? riboflavinMg,
    Value<double?>? niacinMg,
    Value<double?>? pantothenicAcidMg,
    Value<double?>? vitaminB6Mg,
    Value<double?>? folateUg,
    Value<double?>? folateDfeUg,
    Value<double?>? vitaminB12Ug,
    Value<double?>? cholineMg,
    Value<double?>? biotinUg,
    Value<double?>? caffeineMg,
    Value<double?>? theobromineMg,
    Value<double?>? lycopeneUg,
    Value<double?>? luteinZeaxanthinUg,
    Value<int>? updatedAt,
    Value<int>? deleted,
    Value<int>? dirty,
    Value<int>? rowid,
  }) {
    return LogEntriesCompanion(
      id: id ?? this.id,
      foodId: foodId ?? this.foodId,
      customFoodId: customFoodId ?? this.customFoodId,
      loggedAt: loggedAt ?? this.loggedAt,
      grams: grams ?? this.grams,
      portionQty: portionQty ?? this.portionQty,
      portionLabel: portionLabel ?? this.portionLabel,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      fatG: fatG ?? this.fatG,
      carbG: carbG ?? this.carbG,
      fiberG: fiberG ?? this.fiberG,
      sugarG: sugarG ?? this.sugarG,
      starchG: starchG ?? this.starchG,
      waterG: waterG ?? this.waterG,
      ashG: ashG ?? this.ashG,
      alcoholG: alcoholG ?? this.alcoholG,
      satFatG: satFatG ?? this.satFatG,
      monoFatG: monoFatG ?? this.monoFatG,
      polyFatG: polyFatG ?? this.polyFatG,
      transFatG: transFatG ?? this.transFatG,
      cholesterolMg: cholesterolMg ?? this.cholesterolMg,
      omega3EpaG: omega3EpaG ?? this.omega3EpaG,
      omega3DhaG: omega3DhaG ?? this.omega3DhaG,
      calciumMg: calciumMg ?? this.calciumMg,
      ironMg: ironMg ?? this.ironMg,
      magnesiumMg: magnesiumMg ?? this.magnesiumMg,
      phosphorusMg: phosphorusMg ?? this.phosphorusMg,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      zincMg: zincMg ?? this.zincMg,
      copperMg: copperMg ?? this.copperMg,
      manganeseMg: manganeseMg ?? this.manganeseMg,
      seleniumUg: seleniumUg ?? this.seleniumUg,
      fluorideUg: fluorideUg ?? this.fluorideUg,
      iodineUg: iodineUg ?? this.iodineUg,
      vitaminARaeUg: vitaminARaeUg ?? this.vitaminARaeUg,
      retinolUg: retinolUg ?? this.retinolUg,
      caroteneBetaUg: caroteneBetaUg ?? this.caroteneBetaUg,
      vitaminCMg: vitaminCMg ?? this.vitaminCMg,
      vitaminDUg: vitaminDUg ?? this.vitaminDUg,
      vitaminEMg: vitaminEMg ?? this.vitaminEMg,
      vitaminKUg: vitaminKUg ?? this.vitaminKUg,
      thiaminMg: thiaminMg ?? this.thiaminMg,
      riboflavinMg: riboflavinMg ?? this.riboflavinMg,
      niacinMg: niacinMg ?? this.niacinMg,
      pantothenicAcidMg: pantothenicAcidMg ?? this.pantothenicAcidMg,
      vitaminB6Mg: vitaminB6Mg ?? this.vitaminB6Mg,
      folateUg: folateUg ?? this.folateUg,
      folateDfeUg: folateDfeUg ?? this.folateDfeUg,
      vitaminB12Ug: vitaminB12Ug ?? this.vitaminB12Ug,
      cholineMg: cholineMg ?? this.cholineMg,
      biotinUg: biotinUg ?? this.biotinUg,
      caffeineMg: caffeineMg ?? this.caffeineMg,
      theobromineMg: theobromineMg ?? this.theobromineMg,
      lycopeneUg: lycopeneUg ?? this.lycopeneUg,
      luteinZeaxanthinUg: luteinZeaxanthinUg ?? this.luteinZeaxanthinUg,
      updatedAt: updatedAt ?? this.updatedAt,
      deleted: deleted ?? this.deleted,
      dirty: dirty ?? this.dirty,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<int>(foodId.value);
    }
    if (customFoodId.present) {
      map['custom_food_id'] = Variable<String>(customFoodId.value);
    }
    if (loggedAt.present) {
      map['logged_at'] = Variable<String>(loggedAt.value);
    }
    if (grams.present) {
      map['grams'] = Variable<double>(grams.value);
    }
    if (portionQty.present) {
      map['portion_qty'] = Variable<double>(portionQty.value);
    }
    if (portionLabel.present) {
      map['portion_label'] = Variable<String>(portionLabel.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (emoji.present) {
      map['emoji'] = Variable<String>(emoji.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (carbG.present) {
      map['carb_g'] = Variable<double>(carbG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (starchG.present) {
      map['starch_g'] = Variable<double>(starchG.value);
    }
    if (waterG.present) {
      map['water_g'] = Variable<double>(waterG.value);
    }
    if (ashG.present) {
      map['ash_g'] = Variable<double>(ashG.value);
    }
    if (alcoholG.present) {
      map['alcohol_g'] = Variable<double>(alcoholG.value);
    }
    if (satFatG.present) {
      map['sat_fat_g'] = Variable<double>(satFatG.value);
    }
    if (monoFatG.present) {
      map['mono_fat_g'] = Variable<double>(monoFatG.value);
    }
    if (polyFatG.present) {
      map['poly_fat_g'] = Variable<double>(polyFatG.value);
    }
    if (transFatG.present) {
      map['trans_fat_g'] = Variable<double>(transFatG.value);
    }
    if (cholesterolMg.present) {
      map['cholesterol_mg'] = Variable<double>(cholesterolMg.value);
    }
    if (omega3EpaG.present) {
      map['omega3_epa_g'] = Variable<double>(omega3EpaG.value);
    }
    if (omega3DhaG.present) {
      map['omega3_dha_g'] = Variable<double>(omega3DhaG.value);
    }
    if (calciumMg.present) {
      map['calcium_mg'] = Variable<double>(calciumMg.value);
    }
    if (ironMg.present) {
      map['iron_mg'] = Variable<double>(ironMg.value);
    }
    if (magnesiumMg.present) {
      map['magnesium_mg'] = Variable<double>(magnesiumMg.value);
    }
    if (phosphorusMg.present) {
      map['phosphorus_mg'] = Variable<double>(phosphorusMg.value);
    }
    if (potassiumMg.present) {
      map['potassium_mg'] = Variable<double>(potassiumMg.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (zincMg.present) {
      map['zinc_mg'] = Variable<double>(zincMg.value);
    }
    if (copperMg.present) {
      map['copper_mg'] = Variable<double>(copperMg.value);
    }
    if (manganeseMg.present) {
      map['manganese_mg'] = Variable<double>(manganeseMg.value);
    }
    if (seleniumUg.present) {
      map['selenium_ug'] = Variable<double>(seleniumUg.value);
    }
    if (fluorideUg.present) {
      map['fluoride_ug'] = Variable<double>(fluorideUg.value);
    }
    if (iodineUg.present) {
      map['iodine_ug'] = Variable<double>(iodineUg.value);
    }
    if (vitaminARaeUg.present) {
      map['vitamin_a_rae_ug'] = Variable<double>(vitaminARaeUg.value);
    }
    if (retinolUg.present) {
      map['retinol_ug'] = Variable<double>(retinolUg.value);
    }
    if (caroteneBetaUg.present) {
      map['carotene_beta_ug'] = Variable<double>(caroteneBetaUg.value);
    }
    if (vitaminCMg.present) {
      map['vitamin_c_mg'] = Variable<double>(vitaminCMg.value);
    }
    if (vitaminDUg.present) {
      map['vitamin_d_ug'] = Variable<double>(vitaminDUg.value);
    }
    if (vitaminEMg.present) {
      map['vitamin_e_mg'] = Variable<double>(vitaminEMg.value);
    }
    if (vitaminKUg.present) {
      map['vitamin_k_ug'] = Variable<double>(vitaminKUg.value);
    }
    if (thiaminMg.present) {
      map['thiamin_mg'] = Variable<double>(thiaminMg.value);
    }
    if (riboflavinMg.present) {
      map['riboflavin_mg'] = Variable<double>(riboflavinMg.value);
    }
    if (niacinMg.present) {
      map['niacin_mg'] = Variable<double>(niacinMg.value);
    }
    if (pantothenicAcidMg.present) {
      map['pantothenic_acid_mg'] = Variable<double>(pantothenicAcidMg.value);
    }
    if (vitaminB6Mg.present) {
      map['vitamin_b6_mg'] = Variable<double>(vitaminB6Mg.value);
    }
    if (folateUg.present) {
      map['folate_ug'] = Variable<double>(folateUg.value);
    }
    if (folateDfeUg.present) {
      map['folate_dfe_ug'] = Variable<double>(folateDfeUg.value);
    }
    if (vitaminB12Ug.present) {
      map['vitamin_b12_ug'] = Variable<double>(vitaminB12Ug.value);
    }
    if (cholineMg.present) {
      map['choline_mg'] = Variable<double>(cholineMg.value);
    }
    if (biotinUg.present) {
      map['biotin_ug'] = Variable<double>(biotinUg.value);
    }
    if (caffeineMg.present) {
      map['caffeine_mg'] = Variable<double>(caffeineMg.value);
    }
    if (theobromineMg.present) {
      map['theobromine_mg'] = Variable<double>(theobromineMg.value);
    }
    if (lycopeneUg.present) {
      map['lycopene_ug'] = Variable<double>(lycopeneUg.value);
    }
    if (luteinZeaxanthinUg.present) {
      map['lutein_zeaxanthin_ug'] = Variable<double>(luteinZeaxanthinUg.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deleted.present) {
      map['deleted'] = Variable<int>(deleted.value);
    }
    if (dirty.present) {
      map['dirty'] = Variable<int>(dirty.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LogEntriesCompanion(')
          ..write('id: $id, ')
          ..write('foodId: $foodId, ')
          ..write('customFoodId: $customFoodId, ')
          ..write('loggedAt: $loggedAt, ')
          ..write('grams: $grams, ')
          ..write('portionQty: $portionQty, ')
          ..write('portionLabel: $portionLabel, ')
          ..write('name: $name, ')
          ..write('emoji: $emoji, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('fatG: $fatG, ')
          ..write('carbG: $carbG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('starchG: $starchG, ')
          ..write('waterG: $waterG, ')
          ..write('ashG: $ashG, ')
          ..write('alcoholG: $alcoholG, ')
          ..write('satFatG: $satFatG, ')
          ..write('monoFatG: $monoFatG, ')
          ..write('polyFatG: $polyFatG, ')
          ..write('transFatG: $transFatG, ')
          ..write('cholesterolMg: $cholesterolMg, ')
          ..write('omega3EpaG: $omega3EpaG, ')
          ..write('omega3DhaG: $omega3DhaG, ')
          ..write('calciumMg: $calciumMg, ')
          ..write('ironMg: $ironMg, ')
          ..write('magnesiumMg: $magnesiumMg, ')
          ..write('phosphorusMg: $phosphorusMg, ')
          ..write('potassiumMg: $potassiumMg, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('zincMg: $zincMg, ')
          ..write('copperMg: $copperMg, ')
          ..write('manganeseMg: $manganeseMg, ')
          ..write('seleniumUg: $seleniumUg, ')
          ..write('fluorideUg: $fluorideUg, ')
          ..write('iodineUg: $iodineUg, ')
          ..write('vitaminARaeUg: $vitaminARaeUg, ')
          ..write('retinolUg: $retinolUg, ')
          ..write('caroteneBetaUg: $caroteneBetaUg, ')
          ..write('vitaminCMg: $vitaminCMg, ')
          ..write('vitaminDUg: $vitaminDUg, ')
          ..write('vitaminEMg: $vitaminEMg, ')
          ..write('vitaminKUg: $vitaminKUg, ')
          ..write('thiaminMg: $thiaminMg, ')
          ..write('riboflavinMg: $riboflavinMg, ')
          ..write('niacinMg: $niacinMg, ')
          ..write('pantothenicAcidMg: $pantothenicAcidMg, ')
          ..write('vitaminB6Mg: $vitaminB6Mg, ')
          ..write('folateUg: $folateUg, ')
          ..write('folateDfeUg: $folateDfeUg, ')
          ..write('vitaminB12Ug: $vitaminB12Ug, ')
          ..write('cholineMg: $cholineMg, ')
          ..write('biotinUg: $biotinUg, ')
          ..write('caffeineMg: $caffeineMg, ')
          ..write('theobromineMg: $theobromineMg, ')
          ..write('lycopeneUg: $lycopeneUg, ')
          ..write('luteinZeaxanthinUg: $luteinZeaxanthinUg, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deleted: $deleted, ')
          ..write('dirty: $dirty, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncState extends Table with TableInfo<SyncState, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _syncTableMeta = const VerificationMeta(
    'syncTable',
  );
  late final GeneratedColumn<String> syncTable = GeneratedColumn<String>(
    'table_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _cursorMeta = const VerificationMeta('cursor');
  late final GeneratedColumn<String> cursor = GeneratedColumn<String>(
    'cursor',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _syncedAtMeta = const VerificationMeta(
    'syncedAt',
  );
  late final GeneratedColumn<int> syncedAt = GeneratedColumn<int>(
    'synced_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [syncTable, cursor, syncedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('table_name')) {
      context.handle(
        _syncTableMeta,
        syncTable.isAcceptableOrUnknown(data['table_name']!, _syncTableMeta),
      );
    }
    if (data.containsKey('cursor')) {
      context.handle(
        _cursorMeta,
        cursor.isAcceptableOrUnknown(data['cursor']!, _cursorMeta),
      );
    }
    if (data.containsKey('synced_at')) {
      context.handle(
        _syncedAtMeta,
        syncedAt.isAcceptableOrUnknown(data['synced_at']!, _syncedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {syncTable};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      syncTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}table_name'],
      ),
      cursor: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cursor'],
      ),
      syncedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}synced_at'],
      ),
    );
  }

  @override
  SyncState createAlias(String alias) {
    return SyncState(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  /// Dart getter only; SQL column stays `table_name`, which would otherwise
  /// collide with Table.tableName.
  final String? syncTable;
  final String? cursor;
  final int? syncedAt;
  const SyncStateData({this.syncTable, this.cursor, this.syncedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (!nullToAbsent || syncTable != null) {
      map['table_name'] = Variable<String>(syncTable);
    }
    if (!nullToAbsent || cursor != null) {
      map['cursor'] = Variable<String>(cursor);
    }
    if (!nullToAbsent || syncedAt != null) {
      map['synced_at'] = Variable<int>(syncedAt);
    }
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(
      syncTable: syncTable == null && nullToAbsent
          ? const Value.absent()
          : Value(syncTable),
      cursor: cursor == null && nullToAbsent
          ? const Value.absent()
          : Value(cursor),
      syncedAt: syncedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncedAt),
    );
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      syncTable: serializer.fromJson<String?>(json['table_name']),
      cursor: serializer.fromJson<String?>(json['cursor']),
      syncedAt: serializer.fromJson<int?>(json['synced_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'table_name': serializer.toJson<String?>(syncTable),
      'cursor': serializer.toJson<String?>(cursor),
      'synced_at': serializer.toJson<int?>(syncedAt),
    };
  }

  SyncStateData copyWith({
    Value<String?> syncTable = const Value.absent(),
    Value<String?> cursor = const Value.absent(),
    Value<int?> syncedAt = const Value.absent(),
  }) => SyncStateData(
    syncTable: syncTable.present ? syncTable.value : this.syncTable,
    cursor: cursor.present ? cursor.value : this.cursor,
    syncedAt: syncedAt.present ? syncedAt.value : this.syncedAt,
  );
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      syncTable: data.syncTable.present ? data.syncTable.value : this.syncTable,
      cursor: data.cursor.present ? data.cursor.value : this.cursor,
      syncedAt: data.syncedAt.present ? data.syncedAt.value : this.syncedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('syncTable: $syncTable, ')
          ..write('cursor: $cursor, ')
          ..write('syncedAt: $syncedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(syncTable, cursor, syncedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.syncTable == this.syncTable &&
          other.cursor == this.cursor &&
          other.syncedAt == this.syncedAt);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String?> syncTable;
  final Value<String?> cursor;
  final Value<int?> syncedAt;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.syncTable = const Value.absent(),
    this.cursor = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    this.syncTable = const Value.absent(),
    this.cursor = const Value.absent(),
    this.syncedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  static Insertable<SyncStateData> custom({
    Expression<String>? syncTable,
    Expression<String>? cursor,
    Expression<int>? syncedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (syncTable != null) 'table_name': syncTable,
      if (cursor != null) 'cursor': cursor,
      if (syncedAt != null) 'synced_at': syncedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String?>? syncTable,
    Value<String?>? cursor,
    Value<int?>? syncedAt,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      syncTable: syncTable ?? this.syncTable,
      cursor: cursor ?? this.cursor,
      syncedAt: syncedAt ?? this.syncedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (syncTable.present) {
      map['table_name'] = Variable<String>(syncTable.value);
    }
    if (cursor.present) {
      map['cursor'] = Variable<String>(cursor.value);
    }
    if (syncedAt.present) {
      map['synced_at'] = Variable<int>(syncedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('syncTable: $syncTable, ')
          ..write('cursor: $cursor, ')
          ..write('syncedAt: $syncedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final CustomFoods customFoods = CustomFoods(this);
  late final CustomFoodPortions customFoodPortions = CustomFoodPortions(this);
  late final RecipeIngredients recipeIngredients = RecipeIngredients(this);
  late final RecipeSteps recipeSteps = RecipeSteps(this);
  late final RecipeStepIngredients recipeStepIngredients =
      RecipeStepIngredients(this);
  late final CookSession cookSession = CookSession(this);
  late final LogEntries logEntries = LogEntries(this);
  late final SyncState syncState = SyncState(this);
  late final Index ixLogDay = Index(
    'ix_log_day',
    'CREATE INDEX ix_log_day ON log_entries (local_date, logged_at) WHERE deleted = 0',
  );
  late final Index ixLogDirty = Index(
    'ix_log_dirty',
    'CREATE INDEX ix_log_dirty ON log_entries (id) WHERE dirty = 1',
  );
  late final Index ixCustomDirty = Index(
    'ix_custom_dirty',
    'CREATE INDEX ix_custom_dirty ON custom_foods (id) WHERE dirty = 1',
  );
  late final Index ixIngredientOf = Index(
    'ix_ingredient_of',
    'CREATE INDEX ix_ingredient_of ON recipe_ingredients (custom_food_id) WHERE custom_food_id IS NOT NULL',
  );
  late final Index ixCustomBarcode = Index(
    'ix_custom_barcode',
    'CREATE INDEX ix_custom_barcode ON custom_foods (barcode) WHERE barcode IS NOT NULL AND deleted = 0',
  );
  late final Trigger trLogTouch = Trigger(
    'CREATE TRIGGER tr_log_touch AFTER UPDATE ON log_entries WHEN new.updated_at = old.updated_at BEGIN UPDATE log_entries SET updated_at = strftime(\'%s\', \'now\'), dirty = 1 WHERE id = new.id;END',
    'tr_log_touch',
  );
  late final Trigger trCustomTouch = Trigger(
    'CREATE TRIGGER tr_custom_touch AFTER UPDATE ON custom_foods WHEN new.updated_at = old.updated_at BEGIN UPDATE custom_foods SET updated_at = strftime(\'%s\', \'now\'), dirty = 1 WHERE id = new.id;END',
    'tr_custom_touch',
  );
  Selectable<TimelineForDayResult> timelineForDay(String? date) {
    return customSelect(
      'SELECT id, logged_at, name, emoji, grams, portion_qty, portion_label, grams / 100.0 * energy_kcal AS kcal, grams / 100.0 * protein_g AS protein, grams / 100.0 * fat_g AS fat, grams / 100.0 * carb_g AS carb FROM log_entries WHERE deleted = 0 AND local_date = ?1 ORDER BY logged_at',
      variables: [Variable<String>(date)],
      readsFrom: {logEntries},
    ).map(
      (QueryRow row) => TimelineForDayResult(
        id: row.readNullable<String>('id'),
        loggedAt: row.read<String>('logged_at'),
        name: row.read<String>('name'),
        emoji: row.readNullable<String>('emoji'),
        grams: row.read<double>('grams'),
        portionQty: row.readNullable<double>('portion_qty'),
        portionLabel: row.readNullable<String>('portion_label'),
        kcal: row.readNullable<double>('kcal'),
        protein: row.readNullable<double>('protein'),
        fat: row.readNullable<double>('fat'),
        carb: row.readNullable<double>('carb'),
      ),
    );
  }

  Selectable<RecentlyLoggedResult> recentlyLogged(String? since) {
    return customSelect(
      'SELECT food_id, custom_food_id, name, emoji, energy_kcal, protein_g, fat_g, carb_g, grams / coalesce(portion_qty, 1) AS serving_g, portion_label, count(*) AS n, max(logged_at) AS last_at FROM log_entries WHERE deleted = 0 AND local_date >= ?1 GROUP BY food_id, custom_food_id ORDER BY n DESC, last_at DESC LIMIT 20',
      variables: [Variable<String>(since)],
      readsFrom: {logEntries},
    ).map(
      (QueryRow row) => RecentlyLoggedResult(
        foodId: row.readNullable<int>('food_id'),
        customFoodId: row.readNullable<String>('custom_food_id'),
        name: row.read<String>('name'),
        emoji: row.readNullable<String>('emoji'),
        energyKcal: row.readNullable<double>('energy_kcal'),
        proteinG: row.readNullable<double>('protein_g'),
        fatG: row.readNullable<double>('fat_g'),
        carbG: row.readNullable<double>('carb_g'),
        servingG: row.read<double>('serving_g'),
        portionLabel: row.readNullable<String>('portion_label'),
        n: row.read<int>('n'),
        lastAt: row.readNullable<String>('last_at'),
      ),
    );
  }

  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    customFoods,
    customFoodPortions,
    recipeIngredients,
    recipeSteps,
    recipeStepIngredients,
    cookSession,
    logEntries,
    syncState,
    ixLogDay,
    ixLogDirty,
    ixCustomDirty,
    ixIngredientOf,
    ixCustomBarcode,
    trLogTouch,
    trCustomTouch,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('custom_food_portions', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_foods',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_steps', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipe_steps',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_step_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipe_ingredients',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('recipe_step_ingredients', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'recipe_steps',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('cook_session', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'log_entries',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('log_entries', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'custom_foods',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [TableUpdate('custom_foods', kind: UpdateKind.update)],
    ),
  ]);
}

typedef $CustomFoodsCreateCompanionBuilder =
    CustomFoodsCompanion Function({
      Value<String?> id,
      required String name,
      Value<String?> brand,
      Value<String?> barcode,
      Value<String?> emoji,
      Value<int> variableFat,
      Value<double?> servingG,
      Value<String?> servingLabel,
      Value<double?> energyKcal,
      Value<double?> proteinG,
      Value<double?> fatG,
      Value<double?> carbG,
      Value<double?> fiberG,
      Value<double?> sugarG,
      Value<double?> starchG,
      Value<double?> waterG,
      Value<double?> ashG,
      Value<double?> alcoholG,
      Value<double?> satFatG,
      Value<double?> monoFatG,
      Value<double?> polyFatG,
      Value<double?> transFatG,
      Value<double?> cholesterolMg,
      Value<double?> omega3EpaG,
      Value<double?> omega3DhaG,
      Value<double?> calciumMg,
      Value<double?> ironMg,
      Value<double?> magnesiumMg,
      Value<double?> phosphorusMg,
      Value<double?> potassiumMg,
      Value<double?> sodiumMg,
      Value<double?> zincMg,
      Value<double?> copperMg,
      Value<double?> manganeseMg,
      Value<double?> seleniumUg,
      Value<double?> fluorideUg,
      Value<double?> iodineUg,
      Value<double?> vitaminARaeUg,
      Value<double?> retinolUg,
      Value<double?> caroteneBetaUg,
      Value<double?> vitaminCMg,
      Value<double?> vitaminDUg,
      Value<double?> vitaminEMg,
      Value<double?> vitaminKUg,
      Value<double?> thiaminMg,
      Value<double?> riboflavinMg,
      Value<double?> niacinMg,
      Value<double?> pantothenicAcidMg,
      Value<double?> vitaminB6Mg,
      Value<double?> folateUg,
      Value<double?> folateDfeUg,
      Value<double?> vitaminB12Ug,
      Value<double?> cholineMg,
      Value<double?> biotinUg,
      Value<double?> caffeineMg,
      Value<double?> theobromineMg,
      Value<double?> lycopeneUg,
      Value<double?> luteinZeaxanthinUg,
      Value<int> updatedAt,
      Value<int> deleted,
      Value<int> dirty,
      Value<int> rowid,
    });
typedef $CustomFoodsUpdateCompanionBuilder =
    CustomFoodsCompanion Function({
      Value<String?> id,
      Value<String> name,
      Value<String?> brand,
      Value<String?> barcode,
      Value<String?> emoji,
      Value<int> variableFat,
      Value<double?> servingG,
      Value<String?> servingLabel,
      Value<double?> energyKcal,
      Value<double?> proteinG,
      Value<double?> fatG,
      Value<double?> carbG,
      Value<double?> fiberG,
      Value<double?> sugarG,
      Value<double?> starchG,
      Value<double?> waterG,
      Value<double?> ashG,
      Value<double?> alcoholG,
      Value<double?> satFatG,
      Value<double?> monoFatG,
      Value<double?> polyFatG,
      Value<double?> transFatG,
      Value<double?> cholesterolMg,
      Value<double?> omega3EpaG,
      Value<double?> omega3DhaG,
      Value<double?> calciumMg,
      Value<double?> ironMg,
      Value<double?> magnesiumMg,
      Value<double?> phosphorusMg,
      Value<double?> potassiumMg,
      Value<double?> sodiumMg,
      Value<double?> zincMg,
      Value<double?> copperMg,
      Value<double?> manganeseMg,
      Value<double?> seleniumUg,
      Value<double?> fluorideUg,
      Value<double?> iodineUg,
      Value<double?> vitaminARaeUg,
      Value<double?> retinolUg,
      Value<double?> caroteneBetaUg,
      Value<double?> vitaminCMg,
      Value<double?> vitaminDUg,
      Value<double?> vitaminEMg,
      Value<double?> vitaminKUg,
      Value<double?> thiaminMg,
      Value<double?> riboflavinMg,
      Value<double?> niacinMg,
      Value<double?> pantothenicAcidMg,
      Value<double?> vitaminB6Mg,
      Value<double?> folateUg,
      Value<double?> folateDfeUg,
      Value<double?> vitaminB12Ug,
      Value<double?> cholineMg,
      Value<double?> biotinUg,
      Value<double?> caffeineMg,
      Value<double?> theobromineMg,
      Value<double?> lycopeneUg,
      Value<double?> luteinZeaxanthinUg,
      Value<int> updatedAt,
      Value<int> deleted,
      Value<int> dirty,
      Value<int> rowid,
    });

final class $CustomFoodsReferences
    extends BaseReferences<_$AppDatabase, CustomFoods, CustomFood> {
  $CustomFoodsReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<CustomFoodPortions, List<CustomFoodPortion>>
  _customFoodPortionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.customFoodPortions,
        aliasName: 'custom_foods__id__custom_food_portions__custom_food_id',
      );

  $CustomFoodPortionsProcessedTableManager get customFoodPortionsRefs {
    final manager = $CustomFoodPortionsTableManager(
      $_db,
      $_db.customFoodPortions,
    ).filter((f) => f.customFoodId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(
      _customFoodPortionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<RecipeSteps, List<RecipeStep>>
  _recipeStepsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.recipeSteps,
    aliasName: 'custom_foods__id__recipe_steps__recipe_id',
  );

  $RecipeStepsProcessedTableManager get recipeStepsRefs {
    final manager = $RecipeStepsTableManager(
      $_db,
      $_db.recipeSteps,
    ).filter((f) => f.recipeId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_recipeStepsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<LogEntries, List<LogEntry>> _logEntriesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.logEntries,
    aliasName: 'custom_foods__id__log_entries__custom_food_id',
  );

  $LogEntriesProcessedTableManager get logEntriesRefs {
    final manager = $LogEntriesTableManager(
      $_db,
      $_db.logEntries,
    ).filter((f) => f.customFoodId.id.sqlEquals($_itemColumn<String>('id')));

    final cache = $_typedResult.readTableOrNull(_logEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CustomFoodsFilterComposer extends Composer<_$AppDatabase, CustomFoods> {
  $CustomFoodsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get variableFat => $composableBuilder(
    column: $table.variableFat,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingG => $composableBuilder(
    column: $table.servingG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingLabel => $composableBuilder(
    column: $table.servingLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get starchG => $composableBuilder(
    column: $table.starchG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterG => $composableBuilder(
    column: $table.waterG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ashG => $composableBuilder(
    column: $table.ashG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alcoholG => $composableBuilder(
    column: $table.alcoholG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get satFatG => $composableBuilder(
    column: $table.satFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monoFatG => $composableBuilder(
    column: $table.monoFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get polyFatG => $composableBuilder(
    column: $table.polyFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transFatG => $composableBuilder(
    column: $table.transFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cholesterolMg => $composableBuilder(
    column: $table.cholesterolMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get omega3EpaG => $composableBuilder(
    column: $table.omega3EpaG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get omega3DhaG => $composableBuilder(
    column: $table.omega3DhaG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ironMg => $composableBuilder(
    column: $table.ironMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get magnesiumMg => $composableBuilder(
    column: $table.magnesiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zincMg => $composableBuilder(
    column: $table.zincMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get copperMg => $composableBuilder(
    column: $table.copperMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get manganeseMg => $composableBuilder(
    column: $table.manganeseMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get seleniumUg => $composableBuilder(
    column: $table.seleniumUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fluorideUg => $composableBuilder(
    column: $table.fluorideUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get iodineUg => $composableBuilder(
    column: $table.iodineUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminARaeUg => $composableBuilder(
    column: $table.vitaminARaeUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get retinolUg => $composableBuilder(
    column: $table.retinolUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caroteneBetaUg => $composableBuilder(
    column: $table.caroteneBetaUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminDUg => $composableBuilder(
    column: $table.vitaminDUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminEMg => $composableBuilder(
    column: $table.vitaminEMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminKUg => $composableBuilder(
    column: $table.vitaminKUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thiaminMg => $composableBuilder(
    column: $table.thiaminMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riboflavinMg => $composableBuilder(
    column: $table.riboflavinMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get niacinMg => $composableBuilder(
    column: $table.niacinMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pantothenicAcidMg => $composableBuilder(
    column: $table.pantothenicAcidMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminB6Mg => $composableBuilder(
    column: $table.vitaminB6Mg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get folateUg => $composableBuilder(
    column: $table.folateUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get folateDfeUg => $composableBuilder(
    column: $table.folateDfeUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminB12Ug => $composableBuilder(
    column: $table.vitaminB12Ug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cholineMg => $composableBuilder(
    column: $table.cholineMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get biotinUg => $composableBuilder(
    column: $table.biotinUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caffeineMg => $composableBuilder(
    column: $table.caffeineMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get theobromineMg => $composableBuilder(
    column: $table.theobromineMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lycopeneUg => $composableBuilder(
    column: $table.lycopeneUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get luteinZeaxanthinUg => $composableBuilder(
    column: $table.luteinZeaxanthinUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> customFoodPortionsRefs(
    Expression<bool> Function($CustomFoodPortionsFilterComposer f) f,
  ) {
    final $CustomFoodPortionsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customFoodPortions,
      getReferencedColumn: (t) => t.customFoodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodPortionsFilterComposer(
            $db: $db,
            $table: $db.customFoodPortions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> recipeStepsRefs(
    Expression<bool> Function($RecipeStepsFilterComposer f) f,
  ) {
    final $RecipeStepsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecipeStepsFilterComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> logEntriesRefs(
    Expression<bool> Function($LogEntriesFilterComposer f) f,
  ) {
    final $LogEntriesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.customFoodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LogEntriesFilterComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CustomFoodsOrderingComposer
    extends Composer<_$AppDatabase, CustomFoods> {
  $CustomFoodsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get barcode => $composableBuilder(
    column: $table.barcode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get variableFat => $composableBuilder(
    column: $table.variableFat,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingG => $composableBuilder(
    column: $table.servingG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingLabel => $composableBuilder(
    column: $table.servingLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get starchG => $composableBuilder(
    column: $table.starchG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterG => $composableBuilder(
    column: $table.waterG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ashG => $composableBuilder(
    column: $table.ashG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alcoholG => $composableBuilder(
    column: $table.alcoholG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get satFatG => $composableBuilder(
    column: $table.satFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monoFatG => $composableBuilder(
    column: $table.monoFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get polyFatG => $composableBuilder(
    column: $table.polyFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transFatG => $composableBuilder(
    column: $table.transFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cholesterolMg => $composableBuilder(
    column: $table.cholesterolMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get omega3EpaG => $composableBuilder(
    column: $table.omega3EpaG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get omega3DhaG => $composableBuilder(
    column: $table.omega3DhaG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ironMg => $composableBuilder(
    column: $table.ironMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get magnesiumMg => $composableBuilder(
    column: $table.magnesiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zincMg => $composableBuilder(
    column: $table.zincMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get copperMg => $composableBuilder(
    column: $table.copperMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get manganeseMg => $composableBuilder(
    column: $table.manganeseMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get seleniumUg => $composableBuilder(
    column: $table.seleniumUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fluorideUg => $composableBuilder(
    column: $table.fluorideUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get iodineUg => $composableBuilder(
    column: $table.iodineUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminARaeUg => $composableBuilder(
    column: $table.vitaminARaeUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get retinolUg => $composableBuilder(
    column: $table.retinolUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caroteneBetaUg => $composableBuilder(
    column: $table.caroteneBetaUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminDUg => $composableBuilder(
    column: $table.vitaminDUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminEMg => $composableBuilder(
    column: $table.vitaminEMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminKUg => $composableBuilder(
    column: $table.vitaminKUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thiaminMg => $composableBuilder(
    column: $table.thiaminMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riboflavinMg => $composableBuilder(
    column: $table.riboflavinMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get niacinMg => $composableBuilder(
    column: $table.niacinMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pantothenicAcidMg => $composableBuilder(
    column: $table.pantothenicAcidMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminB6Mg => $composableBuilder(
    column: $table.vitaminB6Mg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get folateUg => $composableBuilder(
    column: $table.folateUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get folateDfeUg => $composableBuilder(
    column: $table.folateDfeUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminB12Ug => $composableBuilder(
    column: $table.vitaminB12Ug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cholineMg => $composableBuilder(
    column: $table.cholineMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get biotinUg => $composableBuilder(
    column: $table.biotinUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caffeineMg => $composableBuilder(
    column: $table.caffeineMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get theobromineMg => $composableBuilder(
    column: $table.theobromineMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lycopeneUg => $composableBuilder(
    column: $table.lycopeneUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get luteinZeaxanthinUg => $composableBuilder(
    column: $table.luteinZeaxanthinUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CustomFoodsAnnotationComposer
    extends Composer<_$AppDatabase, CustomFoods> {
  $CustomFoodsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<String> get barcode =>
      $composableBuilder(column: $table.barcode, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<int> get variableFat => $composableBuilder(
    column: $table.variableFat,
    builder: (column) => column,
  );

  GeneratedColumn<double> get servingG =>
      $composableBuilder(column: $table.servingG, builder: (column) => column);

  GeneratedColumn<String> get servingLabel => $composableBuilder(
    column: $table.servingLabel,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get starchG =>
      $composableBuilder(column: $table.starchG, builder: (column) => column);

  GeneratedColumn<double> get waterG =>
      $composableBuilder(column: $table.waterG, builder: (column) => column);

  GeneratedColumn<double> get ashG =>
      $composableBuilder(column: $table.ashG, builder: (column) => column);

  GeneratedColumn<double> get alcoholG =>
      $composableBuilder(column: $table.alcoholG, builder: (column) => column);

  GeneratedColumn<double> get satFatG =>
      $composableBuilder(column: $table.satFatG, builder: (column) => column);

  GeneratedColumn<double> get monoFatG =>
      $composableBuilder(column: $table.monoFatG, builder: (column) => column);

  GeneratedColumn<double> get polyFatG =>
      $composableBuilder(column: $table.polyFatG, builder: (column) => column);

  GeneratedColumn<double> get transFatG =>
      $composableBuilder(column: $table.transFatG, builder: (column) => column);

  GeneratedColumn<double> get cholesterolMg => $composableBuilder(
    column: $table.cholesterolMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get omega3EpaG => $composableBuilder(
    column: $table.omega3EpaG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get omega3DhaG => $composableBuilder(
    column: $table.omega3DhaG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calciumMg =>
      $composableBuilder(column: $table.calciumMg, builder: (column) => column);

  GeneratedColumn<double> get ironMg =>
      $composableBuilder(column: $table.ironMg, builder: (column) => column);

  GeneratedColumn<double> get magnesiumMg => $composableBuilder(
    column: $table.magnesiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get zincMg =>
      $composableBuilder(column: $table.zincMg, builder: (column) => column);

  GeneratedColumn<double> get copperMg =>
      $composableBuilder(column: $table.copperMg, builder: (column) => column);

  GeneratedColumn<double> get manganeseMg => $composableBuilder(
    column: $table.manganeseMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get seleniumUg => $composableBuilder(
    column: $table.seleniumUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fluorideUg => $composableBuilder(
    column: $table.fluorideUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get iodineUg =>
      $composableBuilder(column: $table.iodineUg, builder: (column) => column);

  GeneratedColumn<double> get vitaminARaeUg => $composableBuilder(
    column: $table.vitaminARaeUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get retinolUg =>
      $composableBuilder(column: $table.retinolUg, builder: (column) => column);

  GeneratedColumn<double> get caroteneBetaUg => $composableBuilder(
    column: $table.caroteneBetaUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminDUg => $composableBuilder(
    column: $table.vitaminDUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminEMg => $composableBuilder(
    column: $table.vitaminEMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminKUg => $composableBuilder(
    column: $table.vitaminKUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get thiaminMg =>
      $composableBuilder(column: $table.thiaminMg, builder: (column) => column);

  GeneratedColumn<double> get riboflavinMg => $composableBuilder(
    column: $table.riboflavinMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get niacinMg =>
      $composableBuilder(column: $table.niacinMg, builder: (column) => column);

  GeneratedColumn<double> get pantothenicAcidMg => $composableBuilder(
    column: $table.pantothenicAcidMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminB6Mg => $composableBuilder(
    column: $table.vitaminB6Mg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get folateUg =>
      $composableBuilder(column: $table.folateUg, builder: (column) => column);

  GeneratedColumn<double> get folateDfeUg => $composableBuilder(
    column: $table.folateDfeUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminB12Ug => $composableBuilder(
    column: $table.vitaminB12Ug,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cholineMg =>
      $composableBuilder(column: $table.cholineMg, builder: (column) => column);

  GeneratedColumn<double> get biotinUg =>
      $composableBuilder(column: $table.biotinUg, builder: (column) => column);

  GeneratedColumn<double> get caffeineMg => $composableBuilder(
    column: $table.caffeineMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get theobromineMg => $composableBuilder(
    column: $table.theobromineMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lycopeneUg => $composableBuilder(
    column: $table.lycopeneUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get luteinZeaxanthinUg => $composableBuilder(
    column: $table.luteinZeaxanthinUg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  Expression<T> customFoodPortionsRefs<T extends Object>(
    Expression<T> Function($CustomFoodPortionsAnnotationComposer a) f,
  ) {
    final $CustomFoodPortionsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.customFoodPortions,
      getReferencedColumn: (t) => t.customFoodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodPortionsAnnotationComposer(
            $db: $db,
            $table: $db.customFoodPortions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> recipeStepsRefs<T extends Object>(
    Expression<T> Function($RecipeStepsAnnotationComposer a) f,
  ) {
    final $RecipeStepsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.recipeSteps,
      getReferencedColumn: (t) => t.recipeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RecipeStepsAnnotationComposer(
            $db: $db,
            $table: $db.recipeSteps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> logEntriesRefs<T extends Object>(
    Expression<T> Function($LogEntriesAnnotationComposer a) f,
  ) {
    final $LogEntriesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.logEntries,
      getReferencedColumn: (t) => t.customFoodId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $LogEntriesAnnotationComposer(
            $db: $db,
            $table: $db.logEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CustomFoodsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CustomFoods,
          CustomFood,
          $CustomFoodsFilterComposer,
          $CustomFoodsOrderingComposer,
          $CustomFoodsAnnotationComposer,
          $CustomFoodsCreateCompanionBuilder,
          $CustomFoodsUpdateCompanionBuilder,
          (CustomFood, $CustomFoodsReferences),
          CustomFood,
          PrefetchHooks Function({
            bool customFoodPortionsRefs,
            bool recipeStepsRefs,
            bool logEntriesRefs,
          })
        > {
  $CustomFoodsTableManager(_$AppDatabase db, CustomFoods table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CustomFoodsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CustomFoodsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CustomFoodsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<int> variableFat = const Value.absent(),
                Value<double?> servingG = const Value.absent(),
                Value<String?> servingLabel = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> starchG = const Value.absent(),
                Value<double?> waterG = const Value.absent(),
                Value<double?> ashG = const Value.absent(),
                Value<double?> alcoholG = const Value.absent(),
                Value<double?> satFatG = const Value.absent(),
                Value<double?> monoFatG = const Value.absent(),
                Value<double?> polyFatG = const Value.absent(),
                Value<double?> transFatG = const Value.absent(),
                Value<double?> cholesterolMg = const Value.absent(),
                Value<double?> omega3EpaG = const Value.absent(),
                Value<double?> omega3DhaG = const Value.absent(),
                Value<double?> calciumMg = const Value.absent(),
                Value<double?> ironMg = const Value.absent(),
                Value<double?> magnesiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> zincMg = const Value.absent(),
                Value<double?> copperMg = const Value.absent(),
                Value<double?> manganeseMg = const Value.absent(),
                Value<double?> seleniumUg = const Value.absent(),
                Value<double?> fluorideUg = const Value.absent(),
                Value<double?> iodineUg = const Value.absent(),
                Value<double?> vitaminARaeUg = const Value.absent(),
                Value<double?> retinolUg = const Value.absent(),
                Value<double?> caroteneBetaUg = const Value.absent(),
                Value<double?> vitaminCMg = const Value.absent(),
                Value<double?> vitaminDUg = const Value.absent(),
                Value<double?> vitaminEMg = const Value.absent(),
                Value<double?> vitaminKUg = const Value.absent(),
                Value<double?> thiaminMg = const Value.absent(),
                Value<double?> riboflavinMg = const Value.absent(),
                Value<double?> niacinMg = const Value.absent(),
                Value<double?> pantothenicAcidMg = const Value.absent(),
                Value<double?> vitaminB6Mg = const Value.absent(),
                Value<double?> folateUg = const Value.absent(),
                Value<double?> folateDfeUg = const Value.absent(),
                Value<double?> vitaminB12Ug = const Value.absent(),
                Value<double?> cholineMg = const Value.absent(),
                Value<double?> biotinUg = const Value.absent(),
                Value<double?> caffeineMg = const Value.absent(),
                Value<double?> theobromineMg = const Value.absent(),
                Value<double?> lycopeneUg = const Value.absent(),
                Value<double?> luteinZeaxanthinUg = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> deleted = const Value.absent(),
                Value<int> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomFoodsCompanion(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                emoji: emoji,
                variableFat: variableFat,
                servingG: servingG,
                servingLabel: servingLabel,
                energyKcal: energyKcal,
                proteinG: proteinG,
                fatG: fatG,
                carbG: carbG,
                fiberG: fiberG,
                sugarG: sugarG,
                starchG: starchG,
                waterG: waterG,
                ashG: ashG,
                alcoholG: alcoholG,
                satFatG: satFatG,
                monoFatG: monoFatG,
                polyFatG: polyFatG,
                transFatG: transFatG,
                cholesterolMg: cholesterolMg,
                omega3EpaG: omega3EpaG,
                omega3DhaG: omega3DhaG,
                calciumMg: calciumMg,
                ironMg: ironMg,
                magnesiumMg: magnesiumMg,
                phosphorusMg: phosphorusMg,
                potassiumMg: potassiumMg,
                sodiumMg: sodiumMg,
                zincMg: zincMg,
                copperMg: copperMg,
                manganeseMg: manganeseMg,
                seleniumUg: seleniumUg,
                fluorideUg: fluorideUg,
                iodineUg: iodineUg,
                vitaminARaeUg: vitaminARaeUg,
                retinolUg: retinolUg,
                caroteneBetaUg: caroteneBetaUg,
                vitaminCMg: vitaminCMg,
                vitaminDUg: vitaminDUg,
                vitaminEMg: vitaminEMg,
                vitaminKUg: vitaminKUg,
                thiaminMg: thiaminMg,
                riboflavinMg: riboflavinMg,
                niacinMg: niacinMg,
                pantothenicAcidMg: pantothenicAcidMg,
                vitaminB6Mg: vitaminB6Mg,
                folateUg: folateUg,
                folateDfeUg: folateDfeUg,
                vitaminB12Ug: vitaminB12Ug,
                cholineMg: cholineMg,
                biotinUg: biotinUg,
                caffeineMg: caffeineMg,
                theobromineMg: theobromineMg,
                lycopeneUg: lycopeneUg,
                luteinZeaxanthinUg: luteinZeaxanthinUg,
                updatedAt: updatedAt,
                deleted: deleted,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<String?> barcode = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<int> variableFat = const Value.absent(),
                Value<double?> servingG = const Value.absent(),
                Value<String?> servingLabel = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> starchG = const Value.absent(),
                Value<double?> waterG = const Value.absent(),
                Value<double?> ashG = const Value.absent(),
                Value<double?> alcoholG = const Value.absent(),
                Value<double?> satFatG = const Value.absent(),
                Value<double?> monoFatG = const Value.absent(),
                Value<double?> polyFatG = const Value.absent(),
                Value<double?> transFatG = const Value.absent(),
                Value<double?> cholesterolMg = const Value.absent(),
                Value<double?> omega3EpaG = const Value.absent(),
                Value<double?> omega3DhaG = const Value.absent(),
                Value<double?> calciumMg = const Value.absent(),
                Value<double?> ironMg = const Value.absent(),
                Value<double?> magnesiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> zincMg = const Value.absent(),
                Value<double?> copperMg = const Value.absent(),
                Value<double?> manganeseMg = const Value.absent(),
                Value<double?> seleniumUg = const Value.absent(),
                Value<double?> fluorideUg = const Value.absent(),
                Value<double?> iodineUg = const Value.absent(),
                Value<double?> vitaminARaeUg = const Value.absent(),
                Value<double?> retinolUg = const Value.absent(),
                Value<double?> caroteneBetaUg = const Value.absent(),
                Value<double?> vitaminCMg = const Value.absent(),
                Value<double?> vitaminDUg = const Value.absent(),
                Value<double?> vitaminEMg = const Value.absent(),
                Value<double?> vitaminKUg = const Value.absent(),
                Value<double?> thiaminMg = const Value.absent(),
                Value<double?> riboflavinMg = const Value.absent(),
                Value<double?> niacinMg = const Value.absent(),
                Value<double?> pantothenicAcidMg = const Value.absent(),
                Value<double?> vitaminB6Mg = const Value.absent(),
                Value<double?> folateUg = const Value.absent(),
                Value<double?> folateDfeUg = const Value.absent(),
                Value<double?> vitaminB12Ug = const Value.absent(),
                Value<double?> cholineMg = const Value.absent(),
                Value<double?> biotinUg = const Value.absent(),
                Value<double?> caffeineMg = const Value.absent(),
                Value<double?> theobromineMg = const Value.absent(),
                Value<double?> lycopeneUg = const Value.absent(),
                Value<double?> luteinZeaxanthinUg = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> deleted = const Value.absent(),
                Value<int> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CustomFoodsCompanion.insert(
                id: id,
                name: name,
                brand: brand,
                barcode: barcode,
                emoji: emoji,
                variableFat: variableFat,
                servingG: servingG,
                servingLabel: servingLabel,
                energyKcal: energyKcal,
                proteinG: proteinG,
                fatG: fatG,
                carbG: carbG,
                fiberG: fiberG,
                sugarG: sugarG,
                starchG: starchG,
                waterG: waterG,
                ashG: ashG,
                alcoholG: alcoholG,
                satFatG: satFatG,
                monoFatG: monoFatG,
                polyFatG: polyFatG,
                transFatG: transFatG,
                cholesterolMg: cholesterolMg,
                omega3EpaG: omega3EpaG,
                omega3DhaG: omega3DhaG,
                calciumMg: calciumMg,
                ironMg: ironMg,
                magnesiumMg: magnesiumMg,
                phosphorusMg: phosphorusMg,
                potassiumMg: potassiumMg,
                sodiumMg: sodiumMg,
                zincMg: zincMg,
                copperMg: copperMg,
                manganeseMg: manganeseMg,
                seleniumUg: seleniumUg,
                fluorideUg: fluorideUg,
                iodineUg: iodineUg,
                vitaminARaeUg: vitaminARaeUg,
                retinolUg: retinolUg,
                caroteneBetaUg: caroteneBetaUg,
                vitaminCMg: vitaminCMg,
                vitaminDUg: vitaminDUg,
                vitaminEMg: vitaminEMg,
                vitaminKUg: vitaminKUg,
                thiaminMg: thiaminMg,
                riboflavinMg: riboflavinMg,
                niacinMg: niacinMg,
                pantothenicAcidMg: pantothenicAcidMg,
                vitaminB6Mg: vitaminB6Mg,
                folateUg: folateUg,
                folateDfeUg: folateDfeUg,
                vitaminB12Ug: vitaminB12Ug,
                cholineMg: cholineMg,
                biotinUg: biotinUg,
                caffeineMg: caffeineMg,
                theobromineMg: theobromineMg,
                lycopeneUg: lycopeneUg,
                luteinZeaxanthinUg: luteinZeaxanthinUg,
                updatedAt: updatedAt,
                deleted: deleted,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $CustomFoodsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                customFoodPortionsRefs = false,
                recipeStepsRefs = false,
                logEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (customFoodPortionsRefs) db.customFoodPortions,
                    if (recipeStepsRefs) db.recipeSteps,
                    if (logEntriesRefs) db.logEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (customFoodPortionsRefs)
                        await $_getPrefetchedData<
                          CustomFood,
                          CustomFoods,
                          CustomFoodPortion
                        >(
                          currentTable: table,
                          referencedTable: $CustomFoodsReferences
                              ._customFoodPortionsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CustomFoodsReferences(
                                db,
                                table,
                                p0,
                              ).customFoodPortionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customFoodId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (recipeStepsRefs)
                        await $_getPrefetchedData<
                          CustomFood,
                          CustomFoods,
                          RecipeStep
                        >(
                          currentTable: table,
                          referencedTable: $CustomFoodsReferences
                              ._recipeStepsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CustomFoodsReferences(
                                db,
                                table,
                                p0,
                              ).recipeStepsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.recipeId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (logEntriesRefs)
                        await $_getPrefetchedData<
                          CustomFood,
                          CustomFoods,
                          LogEntry
                        >(
                          currentTable: table,
                          referencedTable: $CustomFoodsReferences
                              ._logEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CustomFoodsReferences(
                                db,
                                table,
                                p0,
                              ).logEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.customFoodId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CustomFoodsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CustomFoods,
      CustomFood,
      $CustomFoodsFilterComposer,
      $CustomFoodsOrderingComposer,
      $CustomFoodsAnnotationComposer,
      $CustomFoodsCreateCompanionBuilder,
      $CustomFoodsUpdateCompanionBuilder,
      (CustomFood, $CustomFoodsReferences),
      CustomFood,
      PrefetchHooks Function({
        bool customFoodPortionsRefs,
        bool recipeStepsRefs,
        bool logEntriesRefs,
      })
    >;
typedef $CustomFoodPortionsCreateCompanionBuilder =
    CustomFoodPortionsCompanion Function({
      required String customFoodId,
      required int seq,
      required String label,
      required double gramWeight,
    });
typedef $CustomFoodPortionsUpdateCompanionBuilder =
    CustomFoodPortionsCompanion Function({
      Value<String> customFoodId,
      Value<int> seq,
      Value<String> label,
      Value<double> gramWeight,
    });

final class $CustomFoodPortionsReferences
    extends
        BaseReferences<_$AppDatabase, CustomFoodPortions, CustomFoodPortion> {
  $CustomFoodPortionsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CustomFoods _customFoodIdTable(_$AppDatabase db) => db.customFoods
      .createAlias('custom_food_portions__custom_food_id__custom_foods__id');

  $CustomFoodsProcessedTableManager get customFoodId {
    final $_column = $_itemColumn<String>('custom_food_id')!;

    final manager = $CustomFoodsTableManager(
      $_db,
      $_db.customFoods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customFoodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CustomFoodPortionsFilterComposer
    extends Composer<_$AppDatabase, CustomFoodPortions> {
  $CustomFoodPortionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get gramWeight => $composableBuilder(
    column: $table.gramWeight,
    builder: (column) => ColumnFilters(column),
  );

  $CustomFoodsFilterComposer get customFoodId {
    final $CustomFoodsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsFilterComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomFoodPortionsOrderingComposer
    extends Composer<_$AppDatabase, CustomFoodPortions> {
  $CustomFoodPortionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get label => $composableBuilder(
    column: $table.label,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get gramWeight => $composableBuilder(
    column: $table.gramWeight,
    builder: (column) => ColumnOrderings(column),
  );

  $CustomFoodsOrderingComposer get customFoodId {
    final $CustomFoodsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsOrderingComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomFoodPortionsAnnotationComposer
    extends Composer<_$AppDatabase, CustomFoodPortions> {
  $CustomFoodPortionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get label =>
      $composableBuilder(column: $table.label, builder: (column) => column);

  GeneratedColumn<double> get gramWeight => $composableBuilder(
    column: $table.gramWeight,
    builder: (column) => column,
  );

  $CustomFoodsAnnotationComposer get customFoodId {
    final $CustomFoodsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsAnnotationComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CustomFoodPortionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CustomFoodPortions,
          CustomFoodPortion,
          $CustomFoodPortionsFilterComposer,
          $CustomFoodPortionsOrderingComposer,
          $CustomFoodPortionsAnnotationComposer,
          $CustomFoodPortionsCreateCompanionBuilder,
          $CustomFoodPortionsUpdateCompanionBuilder,
          (CustomFoodPortion, $CustomFoodPortionsReferences),
          CustomFoodPortion,
          PrefetchHooks Function({bool customFoodId})
        > {
  $CustomFoodPortionsTableManager(_$AppDatabase db, CustomFoodPortions table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CustomFoodPortionsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CustomFoodPortionsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CustomFoodPortionsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> customFoodId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> label = const Value.absent(),
                Value<double> gramWeight = const Value.absent(),
              }) => CustomFoodPortionsCompanion(
                customFoodId: customFoodId,
                seq: seq,
                label: label,
                gramWeight: gramWeight,
              ),
          createCompanionCallback:
              ({
                required String customFoodId,
                required int seq,
                required String label,
                required double gramWeight,
              }) => CustomFoodPortionsCompanion.insert(
                customFoodId: customFoodId,
                seq: seq,
                label: label,
                gramWeight: gramWeight,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CustomFoodPortionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({customFoodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (customFoodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customFoodId,
                                referencedTable: $CustomFoodPortionsReferences
                                    ._customFoodIdTable(db),
                                referencedColumn: $CustomFoodPortionsReferences
                                    ._customFoodIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $CustomFoodPortionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CustomFoodPortions,
      CustomFoodPortion,
      $CustomFoodPortionsFilterComposer,
      $CustomFoodPortionsOrderingComposer,
      $CustomFoodPortionsAnnotationComposer,
      $CustomFoodPortionsCreateCompanionBuilder,
      $CustomFoodPortionsUpdateCompanionBuilder,
      (CustomFoodPortion, $CustomFoodPortionsReferences),
      CustomFoodPortion,
      PrefetchHooks Function({bool customFoodId})
    >;
typedef $RecipeIngredientsCreateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      required String recipeId,
      required int seq,
      Value<int?> foodId,
      Value<String?> customFoodId,
      required double grams,
    });
typedef $RecipeIngredientsUpdateCompanionBuilder =
    RecipeIngredientsCompanion Function({
      Value<String> recipeId,
      Value<int> seq,
      Value<int?> foodId,
      Value<String?> customFoodId,
      Value<double> grams,
    });

final class $RecipeIngredientsReferences
    extends BaseReferences<_$AppDatabase, RecipeIngredients, RecipeIngredient> {
  $RecipeIngredientsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CustomFoods _recipeIdTable(_$AppDatabase db) => db.customFoods
      .createAlias('recipe_ingredients__recipe_id__custom_foods__id');

  $CustomFoodsProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $CustomFoodsTableManager(
      $_db,
      $_db.customFoods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CustomFoods _customFoodIdTable(_$AppDatabase db) => db.customFoods
      .createAlias('recipe_ingredients__custom_food_id__custom_foods__id');

  $CustomFoodsProcessedTableManager? get customFoodId {
    final $_column = $_itemColumn<String>('custom_food_id');
    if ($_column == null) return null;
    final manager = $CustomFoodsTableManager(
      $_db,
      $_db.customFoods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customFoodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $RecipeIngredientsFilterComposer
    extends Composer<_$AppDatabase, RecipeIngredients> {
  $RecipeIngredientsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  $CustomFoodsFilterComposer get recipeId {
    final $CustomFoodsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsFilterComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CustomFoodsFilterComposer get customFoodId {
    final $CustomFoodsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsFilterComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecipeIngredientsOrderingComposer
    extends Composer<_$AppDatabase, RecipeIngredients> {
  $RecipeIngredientsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  $CustomFoodsOrderingComposer get recipeId {
    final $CustomFoodsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsOrderingComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CustomFoodsOrderingComposer get customFoodId {
    final $CustomFoodsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsOrderingComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecipeIngredientsAnnotationComposer
    extends Composer<_$AppDatabase, RecipeIngredients> {
  $RecipeIngredientsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  $CustomFoodsAnnotationComposer get recipeId {
    final $CustomFoodsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsAnnotationComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CustomFoodsAnnotationComposer get customFoodId {
    final $CustomFoodsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsAnnotationComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecipeIngredientsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecipeIngredients,
          RecipeIngredient,
          $RecipeIngredientsFilterComposer,
          $RecipeIngredientsOrderingComposer,
          $RecipeIngredientsAnnotationComposer,
          $RecipeIngredientsCreateCompanionBuilder,
          $RecipeIngredientsUpdateCompanionBuilder,
          (RecipeIngredient, $RecipeIngredientsReferences),
          RecipeIngredient,
          PrefetchHooks Function({bool recipeId, bool customFoodId})
        > {
  $RecipeIngredientsTableManager(_$AppDatabase db, RecipeIngredients table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecipeIngredientsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecipeIngredientsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecipeIngredientsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
                Value<String?> customFoodId = const Value.absent(),
                Value<double> grams = const Value.absent(),
              }) => RecipeIngredientsCompanion(
                recipeId: recipeId,
                seq: seq,
                foodId: foodId,
                customFoodId: customFoodId,
                grams: grams,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required int seq,
                Value<int?> foodId = const Value.absent(),
                Value<String?> customFoodId = const Value.absent(),
                required double grams,
              }) => RecipeIngredientsCompanion.insert(
                recipeId: recipeId,
                seq: seq,
                foodId: foodId,
                customFoodId: customFoodId,
                grams: grams,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $RecipeIngredientsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false, customFoodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $RecipeIngredientsReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $RecipeIngredientsReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (customFoodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customFoodId,
                                referencedTable: $RecipeIngredientsReferences
                                    ._customFoodIdTable(db),
                                referencedColumn: $RecipeIngredientsReferences
                                    ._customFoodIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $RecipeIngredientsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecipeIngredients,
      RecipeIngredient,
      $RecipeIngredientsFilterComposer,
      $RecipeIngredientsOrderingComposer,
      $RecipeIngredientsAnnotationComposer,
      $RecipeIngredientsCreateCompanionBuilder,
      $RecipeIngredientsUpdateCompanionBuilder,
      (RecipeIngredient, $RecipeIngredientsReferences),
      RecipeIngredient,
      PrefetchHooks Function({bool recipeId, bool customFoodId})
    >;
typedef $RecipeStepsCreateCompanionBuilder =
    RecipeStepsCompanion Function({
      required String recipeId,
      required int seq,
      required String stepText,
      Value<int?> durationS,
    });
typedef $RecipeStepsUpdateCompanionBuilder =
    RecipeStepsCompanion Function({
      Value<String> recipeId,
      Value<int> seq,
      Value<String> stepText,
      Value<int?> durationS,
    });

final class $RecipeStepsReferences
    extends BaseReferences<_$AppDatabase, RecipeSteps, RecipeStep> {
  $RecipeStepsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CustomFoods _recipeIdTable(_$AppDatabase db) =>
      db.customFoods.createAlias('recipe_steps__recipe_id__custom_foods__id');

  $CustomFoodsProcessedTableManager get recipeId {
    final $_column = $_itemColumn<String>('recipe_id')!;

    final manager = $CustomFoodsTableManager(
      $_db,
      $_db.customFoods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_recipeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $RecipeStepsFilterComposer extends Composer<_$AppDatabase, RecipeSteps> {
  $RecipeStepsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get stepText => $composableBuilder(
    column: $table.stepText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnFilters(column),
  );

  $CustomFoodsFilterComposer get recipeId {
    final $CustomFoodsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsFilterComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecipeStepsOrderingComposer
    extends Composer<_$AppDatabase, RecipeSteps> {
  $RecipeStepsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get seq => $composableBuilder(
    column: $table.seq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get stepText => $composableBuilder(
    column: $table.stepText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationS => $composableBuilder(
    column: $table.durationS,
    builder: (column) => ColumnOrderings(column),
  );

  $CustomFoodsOrderingComposer get recipeId {
    final $CustomFoodsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsOrderingComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecipeStepsAnnotationComposer
    extends Composer<_$AppDatabase, RecipeSteps> {
  $RecipeStepsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get stepText =>
      $composableBuilder(column: $table.stepText, builder: (column) => column);

  GeneratedColumn<int> get durationS =>
      $composableBuilder(column: $table.durationS, builder: (column) => column);

  $CustomFoodsAnnotationComposer get recipeId {
    final $CustomFoodsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.recipeId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsAnnotationComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RecipeStepsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecipeSteps,
          RecipeStep,
          $RecipeStepsFilterComposer,
          $RecipeStepsOrderingComposer,
          $RecipeStepsAnnotationComposer,
          $RecipeStepsCreateCompanionBuilder,
          $RecipeStepsUpdateCompanionBuilder,
          (RecipeStep, $RecipeStepsReferences),
          RecipeStep,
          PrefetchHooks Function({bool recipeId})
        > {
  $RecipeStepsTableManager(_$AppDatabase db, RecipeSteps table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecipeStepsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecipeStepsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecipeStepsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<int> seq = const Value.absent(),
                Value<String> stepText = const Value.absent(),
                Value<int?> durationS = const Value.absent(),
              }) => RecipeStepsCompanion(
                recipeId: recipeId,
                seq: seq,
                stepText: stepText,
                durationS: durationS,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required int seq,
                required String stepText,
                Value<int?> durationS = const Value.absent(),
              }) => RecipeStepsCompanion.insert(
                recipeId: recipeId,
                seq: seq,
                stepText: stepText,
                durationS: durationS,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $RecipeStepsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({recipeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (recipeId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.recipeId,
                                referencedTable: $RecipeStepsReferences
                                    ._recipeIdTable(db),
                                referencedColumn: $RecipeStepsReferences
                                    ._recipeIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $RecipeStepsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecipeSteps,
      RecipeStep,
      $RecipeStepsFilterComposer,
      $RecipeStepsOrderingComposer,
      $RecipeStepsAnnotationComposer,
      $RecipeStepsCreateCompanionBuilder,
      $RecipeStepsUpdateCompanionBuilder,
      (RecipeStep, $RecipeStepsReferences),
      RecipeStep,
      PrefetchHooks Function({bool recipeId})
    >;
typedef $RecipeStepIngredientsCreateCompanionBuilder =
    RecipeStepIngredientsCompanion Function({
      required String recipeId,
      required int stepSeq,
      required int ingredientSeq,
    });
typedef $RecipeStepIngredientsUpdateCompanionBuilder =
    RecipeStepIngredientsCompanion Function({
      Value<String> recipeId,
      Value<int> stepSeq,
      Value<int> ingredientSeq,
    });

class $RecipeStepIngredientsFilterComposer
    extends Composer<_$AppDatabase, RecipeStepIngredients> {
  $RecipeStepIngredientsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepSeq => $composableBuilder(
    column: $table.stepSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get ingredientSeq => $composableBuilder(
    column: $table.ingredientSeq,
    builder: (column) => ColumnFilters(column),
  );
}

class $RecipeStepIngredientsOrderingComposer
    extends Composer<_$AppDatabase, RecipeStepIngredients> {
  $RecipeStepIngredientsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepSeq => $composableBuilder(
    column: $table.stepSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get ingredientSeq => $composableBuilder(
    column: $table.ingredientSeq,
    builder: (column) => ColumnOrderings(column),
  );
}

class $RecipeStepIngredientsAnnotationComposer
    extends Composer<_$AppDatabase, RecipeStepIngredients> {
  $RecipeStepIngredientsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<int> get stepSeq =>
      $composableBuilder(column: $table.stepSeq, builder: (column) => column);

  GeneratedColumn<int> get ingredientSeq => $composableBuilder(
    column: $table.ingredientSeq,
    builder: (column) => column,
  );
}

class $RecipeStepIngredientsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RecipeStepIngredients,
          RecipeStepIngredient,
          $RecipeStepIngredientsFilterComposer,
          $RecipeStepIngredientsOrderingComposer,
          $RecipeStepIngredientsAnnotationComposer,
          $RecipeStepIngredientsCreateCompanionBuilder,
          $RecipeStepIngredientsUpdateCompanionBuilder,
          (
            RecipeStepIngredient,
            BaseReferences<
              _$AppDatabase,
              RecipeStepIngredients,
              RecipeStepIngredient
            >,
          ),
          RecipeStepIngredient,
          PrefetchHooks Function()
        > {
  $RecipeStepIngredientsTableManager(
    _$AppDatabase db,
    RecipeStepIngredients table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RecipeStepIngredientsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RecipeStepIngredientsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RecipeStepIngredientsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recipeId = const Value.absent(),
                Value<int> stepSeq = const Value.absent(),
                Value<int> ingredientSeq = const Value.absent(),
              }) => RecipeStepIngredientsCompanion(
                recipeId: recipeId,
                stepSeq: stepSeq,
                ingredientSeq: ingredientSeq,
              ),
          createCompanionCallback:
              ({
                required String recipeId,
                required int stepSeq,
                required int ingredientSeq,
              }) => RecipeStepIngredientsCompanion.insert(
                recipeId: recipeId,
                stepSeq: stepSeq,
                ingredientSeq: ingredientSeq,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $RecipeStepIngredientsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RecipeStepIngredients,
      RecipeStepIngredient,
      $RecipeStepIngredientsFilterComposer,
      $RecipeStepIngredientsOrderingComposer,
      $RecipeStepIngredientsAnnotationComposer,
      $RecipeStepIngredientsCreateCompanionBuilder,
      $RecipeStepIngredientsUpdateCompanionBuilder,
      (
        RecipeStepIngredient,
        BaseReferences<
          _$AppDatabase,
          RecipeStepIngredients,
          RecipeStepIngredient
        >,
      ),
      RecipeStepIngredient,
      PrefetchHooks Function()
    >;
typedef $CookSessionCreateCompanionBuilder =
    CookSessionCompanion Function({
      Value<String?> recipeId,
      required int stepSeq,
      Value<int> startedAt,
    });
typedef $CookSessionUpdateCompanionBuilder =
    CookSessionCompanion Function({
      Value<String?> recipeId,
      Value<int> stepSeq,
      Value<int> startedAt,
    });

class $CookSessionFilterComposer extends Composer<_$AppDatabase, CookSession> {
  $CookSessionFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get stepSeq => $composableBuilder(
    column: $table.stepSeq,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $CookSessionOrderingComposer
    extends Composer<_$AppDatabase, CookSession> {
  $CookSessionOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recipeId => $composableBuilder(
    column: $table.recipeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get stepSeq => $composableBuilder(
    column: $table.stepSeq,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $CookSessionAnnotationComposer
    extends Composer<_$AppDatabase, CookSession> {
  $CookSessionAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recipeId =>
      $composableBuilder(column: $table.recipeId, builder: (column) => column);

  GeneratedColumn<int> get stepSeq =>
      $composableBuilder(column: $table.stepSeq, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);
}

class $CookSessionTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CookSession,
          CookSessionData,
          $CookSessionFilterComposer,
          $CookSessionOrderingComposer,
          $CookSessionAnnotationComposer,
          $CookSessionCreateCompanionBuilder,
          $CookSessionUpdateCompanionBuilder,
          (
            CookSessionData,
            BaseReferences<_$AppDatabase, CookSession, CookSessionData>,
          ),
          CookSessionData,
          PrefetchHooks Function()
        > {
  $CookSessionTableManager(_$AppDatabase db, CookSession table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CookSessionFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CookSessionOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CookSessionAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> recipeId = const Value.absent(),
                Value<int> stepSeq = const Value.absent(),
                Value<int> startedAt = const Value.absent(),
              }) => CookSessionCompanion(
                recipeId: recipeId,
                stepSeq: stepSeq,
                startedAt: startedAt,
              ),
          createCompanionCallback:
              ({
                Value<String?> recipeId = const Value.absent(),
                required int stepSeq,
                Value<int> startedAt = const Value.absent(),
              }) => CookSessionCompanion.insert(
                recipeId: recipeId,
                stepSeq: stepSeq,
                startedAt: startedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $CookSessionProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CookSession,
      CookSessionData,
      $CookSessionFilterComposer,
      $CookSessionOrderingComposer,
      $CookSessionAnnotationComposer,
      $CookSessionCreateCompanionBuilder,
      $CookSessionUpdateCompanionBuilder,
      (
        CookSessionData,
        BaseReferences<_$AppDatabase, CookSession, CookSessionData>,
      ),
      CookSessionData,
      PrefetchHooks Function()
    >;
typedef $LogEntriesCreateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<String?> id,
      Value<int?> foodId,
      Value<String?> customFoodId,
      required String loggedAt,
      required double grams,
      Value<double?> portionQty,
      Value<String?> portionLabel,
      required String name,
      Value<String?> emoji,
      Value<double?> energyKcal,
      Value<double?> proteinG,
      Value<double?> fatG,
      Value<double?> carbG,
      Value<double?> fiberG,
      Value<double?> sugarG,
      Value<double?> starchG,
      Value<double?> waterG,
      Value<double?> ashG,
      Value<double?> alcoholG,
      Value<double?> satFatG,
      Value<double?> monoFatG,
      Value<double?> polyFatG,
      Value<double?> transFatG,
      Value<double?> cholesterolMg,
      Value<double?> omega3EpaG,
      Value<double?> omega3DhaG,
      Value<double?> calciumMg,
      Value<double?> ironMg,
      Value<double?> magnesiumMg,
      Value<double?> phosphorusMg,
      Value<double?> potassiumMg,
      Value<double?> sodiumMg,
      Value<double?> zincMg,
      Value<double?> copperMg,
      Value<double?> manganeseMg,
      Value<double?> seleniumUg,
      Value<double?> fluorideUg,
      Value<double?> iodineUg,
      Value<double?> vitaminARaeUg,
      Value<double?> retinolUg,
      Value<double?> caroteneBetaUg,
      Value<double?> vitaminCMg,
      Value<double?> vitaminDUg,
      Value<double?> vitaminEMg,
      Value<double?> vitaminKUg,
      Value<double?> thiaminMg,
      Value<double?> riboflavinMg,
      Value<double?> niacinMg,
      Value<double?> pantothenicAcidMg,
      Value<double?> vitaminB6Mg,
      Value<double?> folateUg,
      Value<double?> folateDfeUg,
      Value<double?> vitaminB12Ug,
      Value<double?> cholineMg,
      Value<double?> biotinUg,
      Value<double?> caffeineMg,
      Value<double?> theobromineMg,
      Value<double?> lycopeneUg,
      Value<double?> luteinZeaxanthinUg,
      Value<int> updatedAt,
      Value<int> deleted,
      Value<int> dirty,
      Value<int> rowid,
    });
typedef $LogEntriesUpdateCompanionBuilder =
    LogEntriesCompanion Function({
      Value<String?> id,
      Value<int?> foodId,
      Value<String?> customFoodId,
      Value<String> loggedAt,
      Value<double> grams,
      Value<double?> portionQty,
      Value<String?> portionLabel,
      Value<String> name,
      Value<String?> emoji,
      Value<double?> energyKcal,
      Value<double?> proteinG,
      Value<double?> fatG,
      Value<double?> carbG,
      Value<double?> fiberG,
      Value<double?> sugarG,
      Value<double?> starchG,
      Value<double?> waterG,
      Value<double?> ashG,
      Value<double?> alcoholG,
      Value<double?> satFatG,
      Value<double?> monoFatG,
      Value<double?> polyFatG,
      Value<double?> transFatG,
      Value<double?> cholesterolMg,
      Value<double?> omega3EpaG,
      Value<double?> omega3DhaG,
      Value<double?> calciumMg,
      Value<double?> ironMg,
      Value<double?> magnesiumMg,
      Value<double?> phosphorusMg,
      Value<double?> potassiumMg,
      Value<double?> sodiumMg,
      Value<double?> zincMg,
      Value<double?> copperMg,
      Value<double?> manganeseMg,
      Value<double?> seleniumUg,
      Value<double?> fluorideUg,
      Value<double?> iodineUg,
      Value<double?> vitaminARaeUg,
      Value<double?> retinolUg,
      Value<double?> caroteneBetaUg,
      Value<double?> vitaminCMg,
      Value<double?> vitaminDUg,
      Value<double?> vitaminEMg,
      Value<double?> vitaminKUg,
      Value<double?> thiaminMg,
      Value<double?> riboflavinMg,
      Value<double?> niacinMg,
      Value<double?> pantothenicAcidMg,
      Value<double?> vitaminB6Mg,
      Value<double?> folateUg,
      Value<double?> folateDfeUg,
      Value<double?> vitaminB12Ug,
      Value<double?> cholineMg,
      Value<double?> biotinUg,
      Value<double?> caffeineMg,
      Value<double?> theobromineMg,
      Value<double?> lycopeneUg,
      Value<double?> luteinZeaxanthinUg,
      Value<int> updatedAt,
      Value<int> deleted,
      Value<int> dirty,
      Value<int> rowid,
    });

final class $LogEntriesReferences
    extends BaseReferences<_$AppDatabase, LogEntries, LogEntry> {
  $LogEntriesReferences(super.$_db, super.$_table, super.$_typedResult);

  static CustomFoods _customFoodIdTable(_$AppDatabase db) => db.customFoods
      .createAlias('log_entries__custom_food_id__custom_foods__id');

  $CustomFoodsProcessedTableManager? get customFoodId {
    final $_column = $_itemColumn<String>('custom_food_id');
    if ($_column == null) return null;
    final manager = $CustomFoodsTableManager(
      $_db,
      $_db.customFoods,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_customFoodIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $LogEntriesFilterComposer extends Composer<_$AppDatabase, LogEntries> {
  $LogEntriesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get portionQty => $composableBuilder(
    column: $table.portionQty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get starchG => $composableBuilder(
    column: $table.starchG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get waterG => $composableBuilder(
    column: $table.waterG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ashG => $composableBuilder(
    column: $table.ashG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get alcoholG => $composableBuilder(
    column: $table.alcoholG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get satFatG => $composableBuilder(
    column: $table.satFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get monoFatG => $composableBuilder(
    column: $table.monoFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get polyFatG => $composableBuilder(
    column: $table.polyFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get transFatG => $composableBuilder(
    column: $table.transFatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cholesterolMg => $composableBuilder(
    column: $table.cholesterolMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get omega3EpaG => $composableBuilder(
    column: $table.omega3EpaG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get omega3DhaG => $composableBuilder(
    column: $table.omega3DhaG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get ironMg => $composableBuilder(
    column: $table.ironMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get magnesiumMg => $composableBuilder(
    column: $table.magnesiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get zincMg => $composableBuilder(
    column: $table.zincMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get copperMg => $composableBuilder(
    column: $table.copperMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get manganeseMg => $composableBuilder(
    column: $table.manganeseMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get seleniumUg => $composableBuilder(
    column: $table.seleniumUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fluorideUg => $composableBuilder(
    column: $table.fluorideUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get iodineUg => $composableBuilder(
    column: $table.iodineUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminARaeUg => $composableBuilder(
    column: $table.vitaminARaeUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get retinolUg => $composableBuilder(
    column: $table.retinolUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caroteneBetaUg => $composableBuilder(
    column: $table.caroteneBetaUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminDUg => $composableBuilder(
    column: $table.vitaminDUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminEMg => $composableBuilder(
    column: $table.vitaminEMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminKUg => $composableBuilder(
    column: $table.vitaminKUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get thiaminMg => $composableBuilder(
    column: $table.thiaminMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get riboflavinMg => $composableBuilder(
    column: $table.riboflavinMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get niacinMg => $composableBuilder(
    column: $table.niacinMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pantothenicAcidMg => $composableBuilder(
    column: $table.pantothenicAcidMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminB6Mg => $composableBuilder(
    column: $table.vitaminB6Mg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get folateUg => $composableBuilder(
    column: $table.folateUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get folateDfeUg => $composableBuilder(
    column: $table.folateDfeUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get vitaminB12Ug => $composableBuilder(
    column: $table.vitaminB12Ug,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get cholineMg => $composableBuilder(
    column: $table.cholineMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get biotinUg => $composableBuilder(
    column: $table.biotinUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get caffeineMg => $composableBuilder(
    column: $table.caffeineMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get theobromineMg => $composableBuilder(
    column: $table.theobromineMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get lycopeneUg => $composableBuilder(
    column: $table.lycopeneUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get luteinZeaxanthinUg => $composableBuilder(
    column: $table.luteinZeaxanthinUg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnFilters(column),
  );

  $CustomFoodsFilterComposer get customFoodId {
    final $CustomFoodsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsFilterComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LogEntriesOrderingComposer extends Composer<_$AppDatabase, LogEntries> {
  $LogEntriesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loggedAt => $composableBuilder(
    column: $table.loggedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get grams => $composableBuilder(
    column: $table.grams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get portionQty => $composableBuilder(
    column: $table.portionQty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get emoji => $composableBuilder(
    column: $table.emoji,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbG => $composableBuilder(
    column: $table.carbG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get starchG => $composableBuilder(
    column: $table.starchG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get waterG => $composableBuilder(
    column: $table.waterG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ashG => $composableBuilder(
    column: $table.ashG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get alcoholG => $composableBuilder(
    column: $table.alcoholG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get satFatG => $composableBuilder(
    column: $table.satFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get monoFatG => $composableBuilder(
    column: $table.monoFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get polyFatG => $composableBuilder(
    column: $table.polyFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get transFatG => $composableBuilder(
    column: $table.transFatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cholesterolMg => $composableBuilder(
    column: $table.cholesterolMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get omega3EpaG => $composableBuilder(
    column: $table.omega3EpaG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get omega3DhaG => $composableBuilder(
    column: $table.omega3DhaG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get calciumMg => $composableBuilder(
    column: $table.calciumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get ironMg => $composableBuilder(
    column: $table.ironMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get magnesiumMg => $composableBuilder(
    column: $table.magnesiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get zincMg => $composableBuilder(
    column: $table.zincMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get copperMg => $composableBuilder(
    column: $table.copperMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get manganeseMg => $composableBuilder(
    column: $table.manganeseMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get seleniumUg => $composableBuilder(
    column: $table.seleniumUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fluorideUg => $composableBuilder(
    column: $table.fluorideUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get iodineUg => $composableBuilder(
    column: $table.iodineUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminARaeUg => $composableBuilder(
    column: $table.vitaminARaeUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get retinolUg => $composableBuilder(
    column: $table.retinolUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caroteneBetaUg => $composableBuilder(
    column: $table.caroteneBetaUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminDUg => $composableBuilder(
    column: $table.vitaminDUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminEMg => $composableBuilder(
    column: $table.vitaminEMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminKUg => $composableBuilder(
    column: $table.vitaminKUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get thiaminMg => $composableBuilder(
    column: $table.thiaminMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get riboflavinMg => $composableBuilder(
    column: $table.riboflavinMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get niacinMg => $composableBuilder(
    column: $table.niacinMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pantothenicAcidMg => $composableBuilder(
    column: $table.pantothenicAcidMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminB6Mg => $composableBuilder(
    column: $table.vitaminB6Mg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get folateUg => $composableBuilder(
    column: $table.folateUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get folateDfeUg => $composableBuilder(
    column: $table.folateDfeUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get vitaminB12Ug => $composableBuilder(
    column: $table.vitaminB12Ug,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get cholineMg => $composableBuilder(
    column: $table.cholineMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get biotinUg => $composableBuilder(
    column: $table.biotinUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get caffeineMg => $composableBuilder(
    column: $table.caffeineMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get theobromineMg => $composableBuilder(
    column: $table.theobromineMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get lycopeneUg => $composableBuilder(
    column: $table.lycopeneUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get luteinZeaxanthinUg => $composableBuilder(
    column: $table.luteinZeaxanthinUg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deleted => $composableBuilder(
    column: $table.deleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dirty => $composableBuilder(
    column: $table.dirty,
    builder: (column) => ColumnOrderings(column),
  );

  $CustomFoodsOrderingComposer get customFoodId {
    final $CustomFoodsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsOrderingComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LogEntriesAnnotationComposer
    extends Composer<_$AppDatabase, LogEntries> {
  $LogEntriesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get loggedAt =>
      $composableBuilder(column: $table.loggedAt, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<double> get grams =>
      $composableBuilder(column: $table.grams, builder: (column) => column);

  GeneratedColumn<double> get portionQty => $composableBuilder(
    column: $table.portionQty,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portionLabel => $composableBuilder(
    column: $table.portionLabel,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get emoji =>
      $composableBuilder(column: $table.emoji, builder: (column) => column);

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get carbG =>
      $composableBuilder(column: $table.carbG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get starchG =>
      $composableBuilder(column: $table.starchG, builder: (column) => column);

  GeneratedColumn<double> get waterG =>
      $composableBuilder(column: $table.waterG, builder: (column) => column);

  GeneratedColumn<double> get ashG =>
      $composableBuilder(column: $table.ashG, builder: (column) => column);

  GeneratedColumn<double> get alcoholG =>
      $composableBuilder(column: $table.alcoholG, builder: (column) => column);

  GeneratedColumn<double> get satFatG =>
      $composableBuilder(column: $table.satFatG, builder: (column) => column);

  GeneratedColumn<double> get monoFatG =>
      $composableBuilder(column: $table.monoFatG, builder: (column) => column);

  GeneratedColumn<double> get polyFatG =>
      $composableBuilder(column: $table.polyFatG, builder: (column) => column);

  GeneratedColumn<double> get transFatG =>
      $composableBuilder(column: $table.transFatG, builder: (column) => column);

  GeneratedColumn<double> get cholesterolMg => $composableBuilder(
    column: $table.cholesterolMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get omega3EpaG => $composableBuilder(
    column: $table.omega3EpaG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get omega3DhaG => $composableBuilder(
    column: $table.omega3DhaG,
    builder: (column) => column,
  );

  GeneratedColumn<double> get calciumMg =>
      $composableBuilder(column: $table.calciumMg, builder: (column) => column);

  GeneratedColumn<double> get ironMg =>
      $composableBuilder(column: $table.ironMg, builder: (column) => column);

  GeneratedColumn<double> get magnesiumMg => $composableBuilder(
    column: $table.magnesiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get phosphorusMg => $composableBuilder(
    column: $table.phosphorusMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get potassiumMg => $composableBuilder(
    column: $table.potassiumMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get zincMg =>
      $composableBuilder(column: $table.zincMg, builder: (column) => column);

  GeneratedColumn<double> get copperMg =>
      $composableBuilder(column: $table.copperMg, builder: (column) => column);

  GeneratedColumn<double> get manganeseMg => $composableBuilder(
    column: $table.manganeseMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get seleniumUg => $composableBuilder(
    column: $table.seleniumUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get fluorideUg => $composableBuilder(
    column: $table.fluorideUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get iodineUg =>
      $composableBuilder(column: $table.iodineUg, builder: (column) => column);

  GeneratedColumn<double> get vitaminARaeUg => $composableBuilder(
    column: $table.vitaminARaeUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get retinolUg =>
      $composableBuilder(column: $table.retinolUg, builder: (column) => column);

  GeneratedColumn<double> get caroteneBetaUg => $composableBuilder(
    column: $table.caroteneBetaUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminCMg => $composableBuilder(
    column: $table.vitaminCMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminDUg => $composableBuilder(
    column: $table.vitaminDUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminEMg => $composableBuilder(
    column: $table.vitaminEMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminKUg => $composableBuilder(
    column: $table.vitaminKUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get thiaminMg =>
      $composableBuilder(column: $table.thiaminMg, builder: (column) => column);

  GeneratedColumn<double> get riboflavinMg => $composableBuilder(
    column: $table.riboflavinMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get niacinMg =>
      $composableBuilder(column: $table.niacinMg, builder: (column) => column);

  GeneratedColumn<double> get pantothenicAcidMg => $composableBuilder(
    column: $table.pantothenicAcidMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminB6Mg => $composableBuilder(
    column: $table.vitaminB6Mg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get folateUg =>
      $composableBuilder(column: $table.folateUg, builder: (column) => column);

  GeneratedColumn<double> get folateDfeUg => $composableBuilder(
    column: $table.folateDfeUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get vitaminB12Ug => $composableBuilder(
    column: $table.vitaminB12Ug,
    builder: (column) => column,
  );

  GeneratedColumn<double> get cholineMg =>
      $composableBuilder(column: $table.cholineMg, builder: (column) => column);

  GeneratedColumn<double> get biotinUg =>
      $composableBuilder(column: $table.biotinUg, builder: (column) => column);

  GeneratedColumn<double> get caffeineMg => $composableBuilder(
    column: $table.caffeineMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get theobromineMg => $composableBuilder(
    column: $table.theobromineMg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get lycopeneUg => $composableBuilder(
    column: $table.lycopeneUg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get luteinZeaxanthinUg => $composableBuilder(
    column: $table.luteinZeaxanthinUg,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deleted =>
      $composableBuilder(column: $table.deleted, builder: (column) => column);

  GeneratedColumn<int> get dirty =>
      $composableBuilder(column: $table.dirty, builder: (column) => column);

  $CustomFoodsAnnotationComposer get customFoodId {
    final $CustomFoodsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.customFoodId,
      referencedTable: $db.customFoods,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CustomFoodsAnnotationComposer(
            $db: $db,
            $table: $db.customFoods,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $LogEntriesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          LogEntries,
          LogEntry,
          $LogEntriesFilterComposer,
          $LogEntriesOrderingComposer,
          $LogEntriesAnnotationComposer,
          $LogEntriesCreateCompanionBuilder,
          $LogEntriesUpdateCompanionBuilder,
          (LogEntry, $LogEntriesReferences),
          LogEntry,
          PrefetchHooks Function({bool customFoodId})
        > {
  $LogEntriesTableManager(_$AppDatabase db, LogEntries table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $LogEntriesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $LogEntriesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $LogEntriesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
                Value<String?> customFoodId = const Value.absent(),
                Value<String> loggedAt = const Value.absent(),
                Value<double> grams = const Value.absent(),
                Value<double?> portionQty = const Value.absent(),
                Value<String?> portionLabel = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> emoji = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> starchG = const Value.absent(),
                Value<double?> waterG = const Value.absent(),
                Value<double?> ashG = const Value.absent(),
                Value<double?> alcoholG = const Value.absent(),
                Value<double?> satFatG = const Value.absent(),
                Value<double?> monoFatG = const Value.absent(),
                Value<double?> polyFatG = const Value.absent(),
                Value<double?> transFatG = const Value.absent(),
                Value<double?> cholesterolMg = const Value.absent(),
                Value<double?> omega3EpaG = const Value.absent(),
                Value<double?> omega3DhaG = const Value.absent(),
                Value<double?> calciumMg = const Value.absent(),
                Value<double?> ironMg = const Value.absent(),
                Value<double?> magnesiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> zincMg = const Value.absent(),
                Value<double?> copperMg = const Value.absent(),
                Value<double?> manganeseMg = const Value.absent(),
                Value<double?> seleniumUg = const Value.absent(),
                Value<double?> fluorideUg = const Value.absent(),
                Value<double?> iodineUg = const Value.absent(),
                Value<double?> vitaminARaeUg = const Value.absent(),
                Value<double?> retinolUg = const Value.absent(),
                Value<double?> caroteneBetaUg = const Value.absent(),
                Value<double?> vitaminCMg = const Value.absent(),
                Value<double?> vitaminDUg = const Value.absent(),
                Value<double?> vitaminEMg = const Value.absent(),
                Value<double?> vitaminKUg = const Value.absent(),
                Value<double?> thiaminMg = const Value.absent(),
                Value<double?> riboflavinMg = const Value.absent(),
                Value<double?> niacinMg = const Value.absent(),
                Value<double?> pantothenicAcidMg = const Value.absent(),
                Value<double?> vitaminB6Mg = const Value.absent(),
                Value<double?> folateUg = const Value.absent(),
                Value<double?> folateDfeUg = const Value.absent(),
                Value<double?> vitaminB12Ug = const Value.absent(),
                Value<double?> cholineMg = const Value.absent(),
                Value<double?> biotinUg = const Value.absent(),
                Value<double?> caffeineMg = const Value.absent(),
                Value<double?> theobromineMg = const Value.absent(),
                Value<double?> lycopeneUg = const Value.absent(),
                Value<double?> luteinZeaxanthinUg = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> deleted = const Value.absent(),
                Value<int> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogEntriesCompanion(
                id: id,
                foodId: foodId,
                customFoodId: customFoodId,
                loggedAt: loggedAt,
                grams: grams,
                portionQty: portionQty,
                portionLabel: portionLabel,
                name: name,
                emoji: emoji,
                energyKcal: energyKcal,
                proteinG: proteinG,
                fatG: fatG,
                carbG: carbG,
                fiberG: fiberG,
                sugarG: sugarG,
                starchG: starchG,
                waterG: waterG,
                ashG: ashG,
                alcoholG: alcoholG,
                satFatG: satFatG,
                monoFatG: monoFatG,
                polyFatG: polyFatG,
                transFatG: transFatG,
                cholesterolMg: cholesterolMg,
                omega3EpaG: omega3EpaG,
                omega3DhaG: omega3DhaG,
                calciumMg: calciumMg,
                ironMg: ironMg,
                magnesiumMg: magnesiumMg,
                phosphorusMg: phosphorusMg,
                potassiumMg: potassiumMg,
                sodiumMg: sodiumMg,
                zincMg: zincMg,
                copperMg: copperMg,
                manganeseMg: manganeseMg,
                seleniumUg: seleniumUg,
                fluorideUg: fluorideUg,
                iodineUg: iodineUg,
                vitaminARaeUg: vitaminARaeUg,
                retinolUg: retinolUg,
                caroteneBetaUg: caroteneBetaUg,
                vitaminCMg: vitaminCMg,
                vitaminDUg: vitaminDUg,
                vitaminEMg: vitaminEMg,
                vitaminKUg: vitaminKUg,
                thiaminMg: thiaminMg,
                riboflavinMg: riboflavinMg,
                niacinMg: niacinMg,
                pantothenicAcidMg: pantothenicAcidMg,
                vitaminB6Mg: vitaminB6Mg,
                folateUg: folateUg,
                folateDfeUg: folateDfeUg,
                vitaminB12Ug: vitaminB12Ug,
                cholineMg: cholineMg,
                biotinUg: biotinUg,
                caffeineMg: caffeineMg,
                theobromineMg: theobromineMg,
                lycopeneUg: lycopeneUg,
                luteinZeaxanthinUg: luteinZeaxanthinUg,
                updatedAt: updatedAt,
                deleted: deleted,
                dirty: dirty,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> id = const Value.absent(),
                Value<int?> foodId = const Value.absent(),
                Value<String?> customFoodId = const Value.absent(),
                required String loggedAt,
                required double grams,
                Value<double?> portionQty = const Value.absent(),
                Value<String?> portionLabel = const Value.absent(),
                required String name,
                Value<String?> emoji = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> carbG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> starchG = const Value.absent(),
                Value<double?> waterG = const Value.absent(),
                Value<double?> ashG = const Value.absent(),
                Value<double?> alcoholG = const Value.absent(),
                Value<double?> satFatG = const Value.absent(),
                Value<double?> monoFatG = const Value.absent(),
                Value<double?> polyFatG = const Value.absent(),
                Value<double?> transFatG = const Value.absent(),
                Value<double?> cholesterolMg = const Value.absent(),
                Value<double?> omega3EpaG = const Value.absent(),
                Value<double?> omega3DhaG = const Value.absent(),
                Value<double?> calciumMg = const Value.absent(),
                Value<double?> ironMg = const Value.absent(),
                Value<double?> magnesiumMg = const Value.absent(),
                Value<double?> phosphorusMg = const Value.absent(),
                Value<double?> potassiumMg = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> zincMg = const Value.absent(),
                Value<double?> copperMg = const Value.absent(),
                Value<double?> manganeseMg = const Value.absent(),
                Value<double?> seleniumUg = const Value.absent(),
                Value<double?> fluorideUg = const Value.absent(),
                Value<double?> iodineUg = const Value.absent(),
                Value<double?> vitaminARaeUg = const Value.absent(),
                Value<double?> retinolUg = const Value.absent(),
                Value<double?> caroteneBetaUg = const Value.absent(),
                Value<double?> vitaminCMg = const Value.absent(),
                Value<double?> vitaminDUg = const Value.absent(),
                Value<double?> vitaminEMg = const Value.absent(),
                Value<double?> vitaminKUg = const Value.absent(),
                Value<double?> thiaminMg = const Value.absent(),
                Value<double?> riboflavinMg = const Value.absent(),
                Value<double?> niacinMg = const Value.absent(),
                Value<double?> pantothenicAcidMg = const Value.absent(),
                Value<double?> vitaminB6Mg = const Value.absent(),
                Value<double?> folateUg = const Value.absent(),
                Value<double?> folateDfeUg = const Value.absent(),
                Value<double?> vitaminB12Ug = const Value.absent(),
                Value<double?> cholineMg = const Value.absent(),
                Value<double?> biotinUg = const Value.absent(),
                Value<double?> caffeineMg = const Value.absent(),
                Value<double?> theobromineMg = const Value.absent(),
                Value<double?> lycopeneUg = const Value.absent(),
                Value<double?> luteinZeaxanthinUg = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> deleted = const Value.absent(),
                Value<int> dirty = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LogEntriesCompanion.insert(
                id: id,
                foodId: foodId,
                customFoodId: customFoodId,
                loggedAt: loggedAt,
                grams: grams,
                portionQty: portionQty,
                portionLabel: portionLabel,
                name: name,
                emoji: emoji,
                energyKcal: energyKcal,
                proteinG: proteinG,
                fatG: fatG,
                carbG: carbG,
                fiberG: fiberG,
                sugarG: sugarG,
                starchG: starchG,
                waterG: waterG,
                ashG: ashG,
                alcoholG: alcoholG,
                satFatG: satFatG,
                monoFatG: monoFatG,
                polyFatG: polyFatG,
                transFatG: transFatG,
                cholesterolMg: cholesterolMg,
                omega3EpaG: omega3EpaG,
                omega3DhaG: omega3DhaG,
                calciumMg: calciumMg,
                ironMg: ironMg,
                magnesiumMg: magnesiumMg,
                phosphorusMg: phosphorusMg,
                potassiumMg: potassiumMg,
                sodiumMg: sodiumMg,
                zincMg: zincMg,
                copperMg: copperMg,
                manganeseMg: manganeseMg,
                seleniumUg: seleniumUg,
                fluorideUg: fluorideUg,
                iodineUg: iodineUg,
                vitaminARaeUg: vitaminARaeUg,
                retinolUg: retinolUg,
                caroteneBetaUg: caroteneBetaUg,
                vitaminCMg: vitaminCMg,
                vitaminDUg: vitaminDUg,
                vitaminEMg: vitaminEMg,
                vitaminKUg: vitaminKUg,
                thiaminMg: thiaminMg,
                riboflavinMg: riboflavinMg,
                niacinMg: niacinMg,
                pantothenicAcidMg: pantothenicAcidMg,
                vitaminB6Mg: vitaminB6Mg,
                folateUg: folateUg,
                folateDfeUg: folateDfeUg,
                vitaminB12Ug: vitaminB12Ug,
                cholineMg: cholineMg,
                biotinUg: biotinUg,
                caffeineMg: caffeineMg,
                theobromineMg: theobromineMg,
                lycopeneUg: lycopeneUg,
                luteinZeaxanthinUg: luteinZeaxanthinUg,
                updatedAt: updatedAt,
                deleted: deleted,
                dirty: dirty,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $LogEntriesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({customFoodId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (customFoodId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.customFoodId,
                                referencedTable: $LogEntriesReferences
                                    ._customFoodIdTable(db),
                                referencedColumn: $LogEntriesReferences
                                    ._customFoodIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $LogEntriesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      LogEntries,
      LogEntry,
      $LogEntriesFilterComposer,
      $LogEntriesOrderingComposer,
      $LogEntriesAnnotationComposer,
      $LogEntriesCreateCompanionBuilder,
      $LogEntriesUpdateCompanionBuilder,
      (LogEntry, $LogEntriesReferences),
      LogEntry,
      PrefetchHooks Function({bool customFoodId})
    >;
typedef $SyncStateCreateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String?> syncTable,
      Value<String?> cursor,
      Value<int?> syncedAt,
      Value<int> rowid,
    });
typedef $SyncStateUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String?> syncTable,
      Value<String?> cursor,
      Value<int?> syncedAt,
      Value<int> rowid,
    });

class $SyncStateFilterComposer extends Composer<_$AppDatabase, SyncState> {
  $SyncStateFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get syncTable => $composableBuilder(
    column: $table.syncTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $SyncStateOrderingComposer extends Composer<_$AppDatabase, SyncState> {
  $SyncStateOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get syncTable => $composableBuilder(
    column: $table.syncTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get cursor => $composableBuilder(
    column: $table.cursor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncedAt => $composableBuilder(
    column: $table.syncedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $SyncStateAnnotationComposer extends Composer<_$AppDatabase, SyncState> {
  $SyncStateAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get syncTable =>
      $composableBuilder(column: $table.syncTable, builder: (column) => column);

  GeneratedColumn<String> get cursor =>
      $composableBuilder(column: $table.cursor, builder: (column) => column);

  GeneratedColumn<int> get syncedAt =>
      $composableBuilder(column: $table.syncedAt, builder: (column) => column);
}

class $SyncStateTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SyncState,
          SyncStateData,
          $SyncStateFilterComposer,
          $SyncStateOrderingComposer,
          $SyncStateAnnotationComposer,
          $SyncStateCreateCompanionBuilder,
          $SyncStateUpdateCompanionBuilder,
          (
            SyncStateData,
            BaseReferences<_$AppDatabase, SyncState, SyncStateData>,
          ),
          SyncStateData,
          PrefetchHooks Function()
        > {
  $SyncStateTableManager(_$AppDatabase db, SyncState table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SyncStateFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SyncStateOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SyncStateAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String?> syncTable = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(
                syncTable: syncTable,
                cursor: cursor,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<String?> syncTable = const Value.absent(),
                Value<String?> cursor = const Value.absent(),
                Value<int?> syncedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                syncTable: syncTable,
                cursor: cursor,
                syncedAt: syncedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $SyncStateProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SyncState,
      SyncStateData,
      $SyncStateFilterComposer,
      $SyncStateOrderingComposer,
      $SyncStateAnnotationComposer,
      $SyncStateCreateCompanionBuilder,
      $SyncStateUpdateCompanionBuilder,
      (SyncStateData, BaseReferences<_$AppDatabase, SyncState, SyncStateData>),
      SyncStateData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $CustomFoodsTableManager get customFoods =>
      $CustomFoodsTableManager(_db, _db.customFoods);
  $CustomFoodPortionsTableManager get customFoodPortions =>
      $CustomFoodPortionsTableManager(_db, _db.customFoodPortions);
  $RecipeIngredientsTableManager get recipeIngredients =>
      $RecipeIngredientsTableManager(_db, _db.recipeIngredients);
  $RecipeStepsTableManager get recipeSteps =>
      $RecipeStepsTableManager(_db, _db.recipeSteps);
  $RecipeStepIngredientsTableManager get recipeStepIngredients =>
      $RecipeStepIngredientsTableManager(_db, _db.recipeStepIngredients);
  $CookSessionTableManager get cookSession =>
      $CookSessionTableManager(_db, _db.cookSession);
  $LogEntriesTableManager get logEntries =>
      $LogEntriesTableManager(_db, _db.logEntries);
  $SyncStateTableManager get syncState =>
      $SyncStateTableManager(_db, _db.syncState);
}

class TimelineForDayResult {
  final String? id;
  final String loggedAt;
  final String name;
  final String? emoji;
  final double grams;
  final double? portionQty;
  final String? portionLabel;
  final double? kcal;
  final double? protein;
  final double? fat;
  final double? carb;
  TimelineForDayResult({
    this.id,
    required this.loggedAt,
    required this.name,
    this.emoji,
    required this.grams,
    this.portionQty,
    this.portionLabel,
    this.kcal,
    this.protein,
    this.fat,
    this.carb,
  });
}

class RecentlyLoggedResult {
  final int? foodId;
  final String? customFoodId;
  final String name;
  final String? emoji;
  final double? energyKcal;
  final double? proteinG;
  final double? fatG;
  final double? carbG;
  final double servingG;
  final String? portionLabel;
  final int n;
  final String? lastAt;
  RecentlyLoggedResult({
    this.foodId,
    this.customFoodId,
    required this.name,
    this.emoji,
    this.energyKcal,
    this.proteinG,
    this.fatG,
    this.carbG,
    required this.servingG,
    this.portionLabel,
    required this.n,
    this.lastAt,
  });
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

final class AppDatabaseProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppDatabase>,
          AppDatabase,
          FutureOr<AppDatabase>
        >
    with $FutureModifier<AppDatabase>, $FutureProvider<AppDatabase> {
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $FutureProviderElement<AppDatabase> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppDatabase> create(Ref ref) {
    return appDatabase(ref);
  }
}

String _$appDatabaseHash() => r'7e09f51465f0bf168cda9e295e365c259bfa71dc';
