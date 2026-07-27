"""Central configuration: paths, thresholds, model name, enums, dictionaries.

Everything tunable lives here so the pipeline modules stay pure logic.
"""
from __future__ import annotations

from pathlib import Path

# --------------------------------------------------------------------------
# Paths
# --------------------------------------------------------------------------
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = PROJECT_ROOT / "data"
RAW_DIR = DATA_DIR / "raw"
EXTRACT_DIR = RAW_DIR / "extracted"
DB_PATH = DATA_DIR / "foods.duckdb"
# Stage 7 export: the read-only catalog bundled into the mobile app. Written
# straight into the Flutter app's asset directory — the app declares
# `database/foods.sqlite` in pubspec.yaml, so there is no copy step to forget.
# Bump `catalogVersion` in lib/core/database/database.dart after every export;
# it is what makes an installed app replace its on-device copy.
SQLITE_PATH = PROJECT_ROOT.parent / "database" / "foods.sqlite"
# The app's own writable database (appdb.log_ddl()), ATTACH-ed beside the
# catalog. The app creates its own on first launch; this is where the notebook
# puts one for development.
LOG_PATH = DATA_DIR / "log.sqlite"

# --------------------------------------------------------------------------
# FDC ingest (Stage 1)
# --------------------------------------------------------------------------
FDC_BASE_URL = "https://fdc.nal.usda.gov"
# The download page has moved between these two URLs across site redesigns;
# discovery tries them all and merges whatever it finds.
FDC_DOWNLOAD_PAGES = (
    "https://fdc.nal.usda.gov/download-datasets",
    "https://fdc.nal.usda.gov/download-datasets.html",
)
FDC_DATASET_PATH = "/fdc-datasets"

# data_type values exactly as they appear in food.csv. Branded is
# deliberately absent: this pipeline only ingests generic foods, and
# data_type itself is the branded/generic signal (never LLM-classified).
TARGET_DATA_TYPES = ("foundation_food", "sr_legacy_food", "survey_fndds_food")

# Archive filename patterns on the download page; group(1) is the version.
ARCHIVE_PATTERNS = {
    "foundation_food": r"FoodData_Central_foundation_food_csv_([\d\-]+)\.zip",
    "sr_legacy_food": r"FoodData_Central_sr_legacy_food_csv_([\d\-]+)\.zip",
    "survey_fndds_food": r"FoodData_Central_survey_food_csv_([\d\-]+)\.zip",
}

# FDC nutrient id for "Total lipid (fat)", grams per 100 g.
FAT_NUTRIENT_ID = 1004

# Nutrients pivoted out of the long food_nutrients table into the wide
# app_food_nutrition table (Stage 7), as canonical (modern) nutrient ids.
# FNDDS stores legacy nutrient_nbr values instead; ingest maps those to these
# ids so one set works for all archives. Add an entry here and the next
# appdb.build picks it up as a new column.
#
# Each entry lists its ids in priority order and the pivot coalesces them:
# USDA measures the same quantity under several ids and no single one covers
# the whole corpus. "Total Sugars" (2000) covers ~11.4k foods but some
# Foundation records only carry "Sugars, Total" (1063) — including
# fdc_id 1105073 — and energy is sometimes only present as an Atwater variant.
#
# Key = the column name, and it carries the unit, because the amount's unit is
# fixed per nutrient id and reproducing USDA's separate unit column 1M times is
# what made the long table heavy in the first place. Anything NOT listed here
# stays in the long table (app_food_nutrients) for the detail-page expander,
# so no value is duplicated between the two.
APP_NUTRIENTS = {
    # macros
    "energy_kcal": (1008, 2047, 2048),
    "protein_g": (1003,),
    "fat_g": (1004,),
    "carb_g": (1005, 1050),
    "fiber_g": (1079, 2033),
    "sugar_g": (2000, 1063),
    "starch_g": (1009,),
    "water_g": (1051,),
    "ash_g": (1007,),
    "alcohol_g": (1018,),
    # fats
    "sat_fat_g": (1258,),
    "mono_fat_g": (1292,),
    "poly_fat_g": (1293,),
    "trans_fat_g": (1257,),
    "cholesterol_mg": (1253,),
    "omega3_epa_g": (1278,),
    "omega3_dha_g": (1272,),
    # minerals
    "calcium_mg": (1087,),
    "iron_mg": (1089,),
    "magnesium_mg": (1090,),
    "phosphorus_mg": (1091,),
    "potassium_mg": (1092,),
    "sodium_mg": (1093,),
    "zinc_mg": (1095,),
    "copper_mg": (1098,),
    "manganese_mg": (1101,),
    "selenium_ug": (1103,),
    "fluoride_ug": (1099,),
    "iodine_ug": (1100,),
    # vitamins
    "vitamin_a_rae_ug": (1106,),
    "retinol_ug": (1105,),
    "carotene_beta_ug": (1107,),
    "vitamin_c_mg": (1162,),
    "vitamin_d_ug": (1114,),
    "vitamin_e_mg": (1109,),
    "vitamin_k_ug": (1185,),
    "thiamin_mg": (1165,),
    "riboflavin_mg": (1166,),
    "niacin_mg": (1167,),
    "pantothenic_acid_mg": (1170,),
    "vitamin_b6_mg": (1175,),
    "folate_ug": (1177,),
    "folate_dfe_ug": (1190,),
    "vitamin_b12_ug": (1178,),
    "choline_mg": (1180,),
    "biotin_ug": (1176,),
    # other
    "caffeine_mg": (1057,),
    "theobromine_mg": (1058,),
    "lycopene_ug": (1122,),
    "lutein_zeaxanthin_ug": (1123,),
}

# The four the search list shows, denormalized onto app_foods so a result row
# is one narrow read with no join. Must be keys of APP_NUTRIENTS.
LIST_MACROS = ("energy_kcal", "protein_g", "fat_g", "carb_g")
assert set(LIST_MACROS) <= set(APP_NUTRIENTS)

# Top-N pairs kept per food in app_food_pairs (Stage 7).
MAX_PAIRS_PER_FOOD = 25

# --------------------------------------------------------------------------
# LLM enrichment (Stage 4) — OpenRouter via the OpenAI-compatible client
# --------------------------------------------------------------------------
OPENROUTER_BASE_URL = "https://openrouter.ai/api/v1"
OPENROUTER_API_KEY_ENV = "OPENROUTER_API_KEY"

# Default model: cheap, fast, supports strict JSON-schema structured outputs
# on OpenRouter. Change here to swap models pipeline-wide.
MODEL = "poolside/laguna-xs-2.1"
# Published price for the default MODEL (USD per 1M tokens) — only a fallback
# for the cost estimate. The real figure comes from OpenRouter's own
# usage.cost (see EnrichmentStats.actual_cost_usd), which is post-discount and
# does not go stale when MODEL changes.
PROMPT_PRICE_PER_M = 0.1288
COMPLETION_PRICE_PER_M = 0.5336

# Prompt caches are per-provider, and OpenRouter load-balances a model across
# several hosts — which shreds the hit rate on a run of identical prefixes.
# Pin one provider slug here once the sample shows which one caches.
# None = let OpenRouter route freely.
PROVIDER_ORDER: tuple[str, ...] | None = None

CONCURRENCY = 48          # asyncio.Semaphore cap on in-flight requests
REQUEST_TIMEOUT_S = 60.0
MAX_RETRIES = 3            # tenacity attempts on 429/5xx/timeouts
SAMPLE_SIZE = 200          # rows for the pre-flight cost/latency sample

# Account-wide request budget the pacer spaces requests out to. Free tiers meter
# requests (~20/min); a paid model meters tokens instead, so pacing only adds
# wall clock. 0 disables it entirely, which is the right setting when paying.
REQUESTS_PER_MINUTE = 0
PROGRESS_EVERY = 25        # rows between progress_cb calls

# Completed rows buffered before one batched write. A run holds the DuckDB file
# lock only for these flushes, so this is both the crash-loss bound and how long
# the database stays openable by anything else. Lower = safer and more sharing,
# at one more attach/checkpoint cycle per N rows.
FLUSH_EVERY = 250

# --------------------------------------------------------------------------
# Confidence routing (Stage 5)
# --------------------------------------------------------------------------
HIGH_THRESHOLD = 0.80      # confidence >= this -> auto_approved, else needs_review

# --------------------------------------------------------------------------
# Search keywords (Stage 4c)
# --------------------------------------------------------------------------
# Kept per food. They are extra FTS text, so more is not better: every keyword
# is another way for this food to surface on a query it does not deserve.
MAX_KEYWORDS = 12
LONGEST_KEYWORD = 40       # chars; longer means the model wrote a sentence

REVIEW_STATUSES = ("pending", "auto_approved", "needs_review", "verified", "rejected")

# --------------------------------------------------------------------------
# Enrichment output enum
# --------------------------------------------------------------------------
PREP_TYPES = (
    "raw", "cooked", "roasted", "baked", "boiled", "fried", "grilled",
    "steamed", "braised", "broiled", "dried", "canned", "frozen", "smoked", "toasted"
)

# --------------------------------------------------------------------------
# Abbreviation expansion (Stage 2)
# --------------------------------------------------------------------------
# Fixed whole-token abbreviation dictionary (Stage 2). Built empirically by
# tokenizing the corpus and ranking tokens by frequency (see
# abbrev.token_frequencies + the diagnostics cell in notebook.py), then
# mapping the cryptic high-frequency ones. Order matters: "w/o" before "w/".
# Each entry: (rule_name, regex_pattern, replacement, case_insensitive).
ABBREVIATION_RULES = (
    ("w/o", r"(?<![\w/])w/o(?![\w/])", "without", True),
    ("w/", r"(?<![\w/])w/(?!o\b)", "with ", True),
    ("NFS", r"\bNFS\b", "not further specified", False),
    ("NS", r"\bNS\b", "not specified", False),
    ("prep", r"\bprep\b\.?", "prepared", True),
    ("reg", r"\breg\b\.?", "regular", True),
    ("incl", r"\bincl\b\.?", "including", True),
    ("approx", r"\bapprox\b\.?", "approximately", True),
    # No "&" -> "and" rule: "&" is not cryptic to a model, and the rule
    # corrupted brand names ("M&M's" -> "M and M's") across 40 rows.
)

# Preparation / nutrition tokens that must NEVER be stripped by any expansion
# rule. There is no stopword removal in this pipeline, but this whitelist is
# enforced by a guard in abbrev.py so future rules can't silently drop them.
PRESERVE_TOKENS = frozenset({
    "raw", "cooked", "roasted", "baked", "boiled", "fried", "grilled",
    "steamed", "braised", "dried", "canned", "frozen", "smoked", "drained",
    "with", "without", "salt", "salted", "unsalted", "lean", "fat",
    "milkfat", "skin", "boneless", "skinless",
})

# --------------------------------------------------------------------------
# SR Legacy brand detection (Stage 3)
# --------------------------------------------------------------------------
# Maintained brand token list, matched case-insensitively on word boundaries
# against the ORIGINAL description (before casing normalization).
BRAND_TOKENS = (
    # fast food / restaurant chains
    "mcdonald", "burger king", "wendy's", "kfc", "kentucky fried",
    "taco bell", "pizza hut", "domino's", "subway", "popeyes",
    "chick-fil-a", "arby's", "dairy queen", "little caesars",
    "papa john's", "denny's", "applebee's", "cracker barrel",
    "olive garden", "t.g.i. friday", "on the border", "carrabba",
    "digiorno", "white castle", "sonic",
    # packaged-food brands
    "kraft", "kellogg", "general mills", "quaker", "nabisco", "hershey",
    "nestle", "oscar mayer", "hormel", "jimmy dean", "louis rich",
    "healthy choice", "lean cuisine", "stouffer", "campbell", "progresso",
    "swanson", "ocean spray", "welch", "del monte", "green giant",
    "birds eye", "ore-ida", "heinz", "hellmann", "best foods", "skippy",
    "smucker", "mission foods", "tyson", "perdue", "butterball",
    "van camp", "george weston", "continental mills", "martha white",
    "pillsbury", "betty crocker", "duncan hines", "hungry jack",
    # candy
    "m&m", "snickers", "twix", "reese", "kit kat", "butterfinger",
    "milky way", "3 musketeers", "starburst", "skittles", "tootsie",
    "mars snackfood", "wm. wrigley", "york peppermint",
    # cereals
    "cheerios", "froot loops", "special k", "rice krispies",
    "frosted flakes", "lucky charms", "cap'n crunch", "chex", "wheaties",
    "grape-nuts", "cream of wheat", "malt-o-meal", "post ",
)

# ALL-CAPS tokens that the proper-noun heuristic must NOT treat as brands.
ALLCAPS_WHITELIST = frozenset({
    "NFS", "NS", "RTE", "USDA", "USA", "BBQ", "IQF", "UHT", "HVP", "RTD",
    "DHA", "EPA", "ALA", "III", "CO2", "LT", "GT",
})

# --------------------------------------------------------------------------
# variable_fat category gate (Stages 4-5)
# --------------------------------------------------------------------------
# variable_fat=true is only allowed when fat_percentage is non-null OR the
# food_category matches one of these meat/dairy keywords (case-insensitive
# substring match on the category description). Prevents false positives
# like "avocado, raw".
MEAT_DAIRY_CATEGORY_KEYWORDS = (
    "beef", "pork", "poultry", "chicken", "turkey", "lamb", "veal", "game",
    "sausage", "luncheon", "cured meat", "cold cuts", "ground meat",
    "dairy", "milk", "cheese", "yogurt", "cream", "egg",
)


def is_meat_dairy_category(food_category: str | None) -> bool:
    """True when the category passes the variable_fat gate."""
    if not food_category:
        return False
    lowered = food_category.lower()
    return any(k in lowered for k in MEAT_DAIRY_CATEGORY_KEYWORDS)


# --------------------------------------------------------------------------
# Merge / dedup (Stage 6b)
# --------------------------------------------------------------------------
# Which macros define "same base ingredients". Keys into APP_NUTRIENTS above,
# not raw ids, so the fallback lists (carb_g -> 1005 then 1050) stay written
# down exactly once.
MERGE_MACRO_KEYS = ("protein_g", "carb_g", "fat_g")
assert set(MERGE_MACRO_KEYS) <= set(APP_NUTRIENTS)

# Euclidean radius on the normalized protein/carb/fat simplex (each coordinate
# is that macro's share of the three, so it sums to 1). Two foods inside this
# radius are the same base ingredients: a ratio is invariant to water, so raw
# and cooked land on the same point, and to seasoning, so salted and unsalted
# do too. Adding oil moves the point off it, which is what keeps an omelette
# out of the egg group.
#
# THE tuning knob. Lower splits preparations of one food apart; higher starts
# pulling genuinely different foods together. 0.05 was picked by inspecting the
# egg / ground beef / milk / tilapia groups on the full corpus.
MERGE_DISTANCE = 0.05

# Foods at or above this fat share are excluded from the fat-variant path
# below. Without it, "Chicken fat, raw" merges into "Canned chicken": on the
# fat-free basis a pure fat looks like whatever it was rendered from.
MERGE_PURE_FAT_RATIO = 0.90

# Dropped from a display_name before it becomes a blocking key, so the key
# names the food and nothing else. Preparation words come from PREP_TYPES;
# the rest are qualifiers that describe handling, grade or trim rather than
# ingredients.
#
# The other tuning surface: a word missing here splits a group that should
# merge ("Chicken breast" vs "Chicken breast meat"), and a food word wrongly
# added here merges two foods that should stay apart.
MERGE_STOPWORDS = frozenset(PREP_TYPES) | frozenset({
    # preparation verbs PREP_TYPES does not carry
    "poached", "scrambled", "stewed", "pan", "browned", "broiled", "drained",
    "prepared", "heated", "unheated", "refrigerated", "cooking",
    # doneness / texture: "soft-boiled" and "hard-boiled" are the same egg
    "soft", "hard", "firm", "tender",
    # seasoning and salt: no meaningful macros, so not a different ingredient
    "salt", "salted", "unsalted", "seasoned", "spice", "spiced", "pepper",
    # grade / trim / cut descriptors
    "lean", "fat", "trimmed", "boneless", "skinless", "separable", "retail",
    "grade", "large", "medium", "small", "piece", "cut", "sliced", "slice",
    "chopped", "meat",
    # generic handling and packaging
    "enriched", "unenriched", "pasteurized", "homemade", "recipe", "made",
    "commercial", "commercially", "style", "variety", "type", "mix",
    "regular", "plain", "whole", "reduced", "low", "light", "fresh", "dry",
    "assorted", "including", "approximately", "specified", "further",
    # function words that survive the length filter
    "with", "without", "and", "the", "not", "added", "from", "all", "only",
})


def merge_macro_nutrients() -> dict[str, tuple[int, ...]]:
    """The APP_NUTRIENTS sub-dict Stage 6b pivots, for store.pivot_columns_sql."""
    return {k: APP_NUTRIENTS[k] for k in MERGE_MACRO_KEYS}
