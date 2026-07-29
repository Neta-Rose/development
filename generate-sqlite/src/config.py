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
# Search keywords (Stage 4)
# --------------------------------------------------------------------------
# Kept per merged item. They are extra FTS text, so more is not better: every
# keyword is another way for this item to surface on a query it does not
# deserve. 20 rather than the 12 that applied per-food — a keyword now has to
# cover every preparation of the item, not one USDA row.
MAX_KEYWORDS = 20
LONGEST_KEYWORD = 40       # chars; longer means the model wrote a sentence

# Member descriptions shown per preparation in a Stage 4 request. Members of
# one preparation are near-duplicates by construction (that is what put them
# together), so past a handful they only cost tokens.
MAX_GROUP_DESCRIPTIONS = 4

# --------------------------------------------------------------------------
# Canonicalization (Stage 3b-1) — the LLM pass that extracts food identity
# --------------------------------------------------------------------------
# Foods per request. This is a consistency knob far more than a cost one: the
# candidates are ordered so that siblings are adjacent, so a big batch is what
# puts "Rice, white, steamed" and "Rice, white, raw" in front of the model at
# the same time and gets ONE base name back for both. Too big and recall on the
# echoed index starts slipping; 40 is the compromise.
CANON_BATCH_SIZE = 40

# FNDDS ingredient descriptions shown per food. The full list runs to a dozen
# rows of "Salt, table" / "Oil or table fat, NFS"; the head of it is what says
# whether this is a dish.
MAX_INPUT_FOODS = 6

# What a food IS, structurally. The whole point of the distinction: a dish is
# not a preparation of the ingredient it is made of, so fried rice can never
# join white rice however similar the two descriptions read.
FOOD_KINDS = ("ingredient", "dish")

# Specific preparation verb -> the widest label that still describes it.
# Preparations are bucketed by the label Stage 3b-1 read off the description;
# when two buckets turn out to have the same macros they are one preparation,
# and it needs a name that covers both. Grilled and baked chicken land on the
# same numbers and are "cooked"; raw and dried have no parent and never merge
# into anything.
PREP_PARENT = {
    "roasted": "cooked", "baked": "cooked", "boiled": "cooked",
    "fried": "cooked", "grilled": "cooked", "steamed": "cooked",
    "braised": "cooked", "broiled": "cooked", "poached": "cooked",
    "scrambled": "cooked", "stewed": "cooked", "microwaved": "cooked",
    "sauteed": "cooked", "blanched": "cooked", "toasted": "cooked",
}

REVIEW_STATUSES = ("pending", "auto_approved", "needs_review", "verified", "rejected")

# --------------------------------------------------------------------------
# Enrichment output enum
# --------------------------------------------------------------------------
# The preparation labels the UI's variant selector shows. A closed enum rather
# than free text: the same state has to read the same way across every item, or
# the selector shows "pan-fried" on one food and "fried" on the next.
#
# "cooked" is the deliberate catch-all. When grilling, boiling and baking land
# on one macro profile they are one preparation and it is called "cooked"; the
# specific verbs are only used when the macros actually separate them.
PREP_TYPES = (
    "raw", "cooked", "roasted", "baked", "boiled", "fried", "grilled",
    "steamed", "braised", "broiled", "dried", "canned", "frozen", "smoked",
    "toasted", "poached", "scrambled", "stewed", "microwaved", "sauteed",
    "blanched", "pickled", "cured", "breaded", "drained",
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
# Clustering / dedup (Stage 3b)
# --------------------------------------------------------------------------
# Which macros define "same base ingredients". Keys into APP_NUTRIENTS above,
# not raw ids, so the fallback lists (carb_g -> 1005 then 1050) stay written
# down exactly once.
MERGE_MACRO_KEYS = ("protein_g", "carb_g", "fat_g")
assert set(MERGE_MACRO_KEYS) <= set(APP_NUTRIENTS)

# Identity is NOT decided here any more. It is a key — the normalized
# base_name Stage 3b-1 extracted — and two foods are the same item when that
# key and food_kind match, full stop.
#
# The two thresholds that used to live here (CLUSTER_JACCARD over description
# tokens, MERGE_DISTANCE over the protein/carb/fat simplex) are gone, and so is
# MERGE_STOPWORDS. Measured on the 13,694-food corpus they could not be tuned
# into agreement: word overlap cannot tell an ingredient word from a handling
# word, so "granola bars, hard, almond" and "granola bars, hard, plain" scored
# 0.75 and merged; and macros are not an identity signal at all, so 6,586
# token-similar pairs were rejected by the ratio test, 698 of them the same
# food recorded in two USDA databases. Both are semantic judgments, which is
# why they moved to the LLM pass in canon.py.
#
# Macros still decide PREPARATIONS below, which is what they are actually
# good at.

# --- Level 3: preparations inside one item ---------------------------------
# Members of an item are the same *preparation* when their absolute per-100 g
# macros agree. Water is what separates preparations: raw chicken thigh is
# 19.7 g protein and cooked is 24.8 g, because cooking drives water off.
#
# Relative Chebyshev distance (the worst macro's relative gap), so the test
# means the same thing for a 2 g-protein vegetable and a 25 g-protein meat.
# 0.20 rather than 0.15: two USDA records of roasted vs stewed thigh differ by
# 1.6 g of fat and split at 0.163, and "grilled, boiled and baked are one
# preparation" is the requirement. Raw vs cooked thigh is 0.50 and still splits.
PREP_DISTANCE = 0.20

# Denominator floor for the relative distance above. Without it a 1 g vs 2 g
# fat difference reads as a 50% gap and shatters every lean vegetable into
# singleton preparations; at 5 g a difference must clear 1 g absolute before it
# registers at all.
PREP_FLOOR_G = 5.0

# Function words dropped when a base_name is normalized into a base_key, so
# "beef, ground" and "ground beef" key alike.
#
# This is deliberately TINY, and the contrast with the 60-word MERGE_STOPWORDS
# it replaces is the point. That list had to decide which words carried food
# identity, and it got the call wrong in both directions ("plain" dropped,
# merging two different granola bars; "meat" dropped, so "without meat" said
# nothing). Nothing here can make that mistake: every word listed is a word
# that cannot distinguish two foods on its own. The identity call is made once,
# by canon.py, and is already baked into base_name by the time this runs.
#
# "with"/"without" are NOT here — "with skin" and "without meat" are exactly
# the macro-bearing qualifiers a base_name is supposed to keep.
BASE_KEY_STOPWORDS = frozenset({"the", "a", "an", "and", "or", "of", "in"})


def merge_macro_nutrients() -> dict[str, tuple[int, ...]]:
    """The APP_NUTRIENTS sub-dict Stage 6b pivots, for store.pivot_columns_sql."""
    return {k: APP_NUTRIENTS[k] for k in MERGE_MACRO_KEYS}
