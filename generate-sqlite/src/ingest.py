"""Stage 1 — Ingest USDA FoodData Central bulk archives.

Only Foundation Foods, SR Legacy and FNDDS (Survey) are ingested; Branded is
deliberately excluded. ``data_type`` is recorded verbatim from food.csv —
it IS the branded/generic classification signal and is never LLM-derived.

``load_frames`` returns one frame per table: ``foods`` (one row per food, with
its USDA metadata) plus the long-form child tables ``nutrients`` (every macro
and micronutrient, not just fat), ``portions`` (household measures and their
gram weights), ``attributes`` and ``input_foods``.

Download links are discovered at runtime by scraping FDC's download-datasets
page (archives are re-released periodically, so URLs are not hardcoded).
If discovery or download fails, the loader falls back to archives the user
placed manually in ``data/raw/``.
"""
from __future__ import annotations

import re
import zipfile
from dataclasses import dataclass
from pathlib import Path

import httpx
import polars as pl

from . import config

# CSV members we actually need from each archive (matched by basename).
NEEDED_FILES = {
    "food.csv",
    "food_attribute.csv",
    "food_attribute_type.csv",
    "food_category.csv",
    "food_nutrient.csv",
    "food_portion.csv",
    "foundation_food.csv",
    "input_food.csv",
    "measure_unit.csv",
    "nutrient.csv",
    "sr_legacy_food.csv",
    "survey_fndds_food.csv",
    "wweia_food_category.csv",
}

# Per-archive metadata table: fdc_id plus whichever of the uniform metadata
# columns that archive happens to ship.
METADATA_FILES = {
    "foundation_food": "foundation_food.csv",
    "sr_legacy_food": "sr_legacy_food.csv",
    "survey_fndds_food": "survey_fndds_food.csv",
}

_NUTRIENT_SCHEMA = {
    "fdc_id": pl.Int64,
    "nutrient_id": pl.Int64,
    "nutrient_name": pl.Utf8,
    "unit_name": pl.Utf8,
    "nutrient_rank": pl.Float64,
    "amount": pl.Float64,
}

_PORTION_SCHEMA = {
    "fdc_id": pl.Int64,
    "seq_num": pl.Int64,
    "measure_unit": pl.Utf8,
    "portion_description": pl.Utf8,
    "modifier": pl.Utf8,
    "gram_weight": pl.Float64,
    "data_points": pl.Int64,
    "footnote": pl.Utf8,
}

_ATTRIBUTE_SCHEMA = {
    "fdc_id": pl.Int64,
    "seq_num": pl.Int64,
    "attribute_type": pl.Utf8,
    "name": pl.Utf8,
    "value": pl.Utf8,
}

_INPUT_FOOD_SCHEMA = {
    "fdc_id": pl.Int64,
    "seq_num": pl.Int64,
    "fdc_of_input_food": pl.Int64,
    "amount": pl.Float64,
    "ingredient_code": pl.Utf8,
    "ingredient_description": pl.Utf8,
    "unit": pl.Utf8,
    "portion_description": pl.Utf8,
    "gram_weight": pl.Float64,
    "retention_code": pl.Utf8,
}

_METADATA_SCHEMA = {
    "fdc_id": pl.Int64,
    "ndb_number": pl.Utf8,
    "food_code": pl.Utf8,
    "wweia_category_number": pl.Utf8,
    "start_date": pl.Date,
    "end_date": pl.Date,
    "usda_footnote": pl.Utf8,
}

# Child tables keyed by fdc_id, in the order load_frames returns them.
CHILD_TABLES = ("nutrients", "portions", "attributes", "input_foods")

_ZIP_URL_RE = re.compile(r"[\w./:%\-]*FoodData_Central_[\w.\-]+\.zip")


@dataclass(frozen=True)
class Archive:
    data_type: str
    version: str
    path: Path


def discover_archive_urls(timeout: float = 30.0) -> dict[str, str]:
    """Scrape the FDC download page(s) for the current full-download zip URLs.

    Returns {data_type: absolute_url} for whichever target types were found;
    when several versions of one archive appear, the newest (lexicographically
    greatest YYYY-MM[-DD] version) wins.
    """
    html_parts: list[str] = []
    for page in config.FDC_DOWNLOAD_PAGES:
        try:
            resp = httpx.get(page, timeout=timeout, follow_redirects=True)
            resp.raise_for_status()
            html_parts.append(resp.text)
        except httpx.HTTPError:
            continue
    html = "\n".join(html_parts)
    if not html:
        return {}

    urls: dict[str, str] = {}
    best_version: dict[str, str] = {}
    for candidate in _ZIP_URL_RE.findall(html):
        for data_type, pattern in config.ARCHIVE_PATTERNS.items():
            m = re.search(pattern, candidate)
            if not m:
                continue
            version = m.group(1)
            if version <= best_version.get(data_type, ""):
                continue
            if candidate.startswith("http"):
                url = candidate
            elif candidate.startswith("/"):
                url = config.FDC_BASE_URL + candidate
            else:
                url = f"{config.FDC_BASE_URL}{config.FDC_DATASET_PATH}/{candidate.rsplit('/', 1)[-1]}"
            best_version[data_type] = version
            urls[data_type] = url
    return urls


def download_archive(url: str, dest_dir: Path, timeout: float = 120.0) -> Path:
    """Stream one archive to dest_dir. Idempotent: existing non-empty file wins."""
    dest_dir.mkdir(parents=True, exist_ok=True)
    dest = dest_dir / url.rsplit("/", 1)[-1]
    if dest.exists() and dest.stat().st_size > 0:
        return dest
    tmp = dest.with_suffix(".part")
    with httpx.stream("GET", url, timeout=timeout, follow_redirects=True) as resp:
        resp.raise_for_status()
        with tmp.open("wb") as fh:
            for chunk in resp.iter_bytes(chunk_size=1 << 20):
                fh.write(chunk)
    tmp.rename(dest)
    return dest


def _newest_local(raw_dir: Path, data_type: str) -> Path | None:
    """Fallback: newest matching archive the user dropped into data/raw/."""
    pattern = config.ARCHIVE_PATTERNS[data_type]
    matches = [p for p in raw_dir.glob("*.zip") if re.search(pattern, p.name)]
    if not matches:
        return None
    return max(matches, key=lambda p: re.search(pattern, p.name).group(1))


def _version_of(path: Path, data_type: str) -> str:
    m = re.search(config.ARCHIVE_PATTERNS[data_type], path.name)
    return m.group(1) if m else "unknown"


def ensure_archives(raw_dir: Path = config.RAW_DIR) -> dict[str, Archive]:
    """Locate (downloading when possible) one archive per target data type."""
    raw_dir.mkdir(parents=True, exist_ok=True)
    try:
        urls = discover_archive_urls()
    except Exception:
        urls = {}

    archives: dict[str, Archive] = {}
    errors: list[str] = []
    for data_type in config.TARGET_DATA_TYPES:
        path: Path | None = None
        if data_type in urls:
            try:
                path = download_archive(urls[data_type], raw_dir)
            except Exception as exc:  # fall back to local copies below
                errors.append(f"{data_type}: download failed ({exc})")
        if path is None:
            path = _newest_local(raw_dir, data_type)
        if path is None:
            raise FileNotFoundError(
                f"No archive for {data_type}. Automatic discovery/download "
                f"failed ({'; '.join(errors) or 'no link found on the download page'}). "
                f"Download the '{data_type}' full CSV zip manually from "
                f"{config.FDC_DOWNLOAD_PAGES[0]} and place it in {raw_dir}/."
            )
        archives[data_type] = Archive(data_type, _version_of(path, data_type), path)
    return archives


def extract_archive(archive: Archive, extract_root: Path = config.EXTRACT_DIR) -> Path:
    """Extract only the needed CSVs, flattened, into a per-version directory."""
    dest = extract_root / f"{archive.data_type}_{archive.version}"
    dest.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(archive.path) as zf:
        for member in zf.namelist():
            basename = member.rsplit("/", 1)[-1]
            if basename not in NEEDED_FILES:
                continue
            target = dest / basename
            if target.exists() and target.stat().st_size > 0:
                continue
            with zf.open(member) as src, target.open("wb") as dst:
                while chunk := src.read(1 << 20):
                    dst.write(chunk)
    return dest


def _read_csv(path: Path) -> pl.DataFrame:
    # FDC CSVs have inconsistent typing; read everything as Utf8 and cast.
    return pl.read_csv(path, infer_schema_length=0)


def _int_col(df: pl.DataFrame, name: str) -> pl.Expr:
    # id columns sometimes appear as "1100" or "1100.0"
    return pl.col(name).cast(pl.Float64, strict=False).cast(pl.Int64, strict=False)


def _float_col(df: pl.DataFrame, name: str) -> pl.Expr:
    return pl.col(name).cast(pl.Float64, strict=False)


def _date_col(df: pl.DataFrame, name: str) -> pl.Expr:
    # every date field in the FDC CSVs is ISO YYYY-MM-DD
    return pl.col(name).str.to_date("%Y-%m-%d", strict=False)


def _opt_col(df: pl.DataFrame, name: str, dtype: pl.DataType = pl.Utf8) -> pl.Expr:
    """Column if the archive ships it, else a typed null of the same name."""
    return pl.col(name) if name in df.columns else pl.lit(None, dtype=dtype).alias(name)


def _in_ids(fdc_ids: pl.Series) -> pl.Expr:
    """Restrict a child table to the foods that survived the data_type filter.
    ``implode`` keeps this a membership test rather than an element-wise one."""
    return pl.col("fdc_id").is_in(fdc_ids.implode())


def _lookup(dir_: Path, filename: str, value_col: str) -> dict[int, str]:
    """id -> label from a small two-column FDC lookup CSV (measure_unit, etc.).

    measure_unit.csv and food_attribute_type.csv are identical across all three
    archives, so the resolved label is denormalized straight onto the child row
    rather than mirrored into its own table.
    """
    path = dir_ / filename
    if not path.exists():
        return {}
    df = _read_csv(path)
    if not {"id", value_col} <= set(df.columns):
        return {}
    df = df.select(_int_col(df, "id").alias("id"), pl.col(value_col)).drop_nulls("id")
    return dict(zip(df["id"].to_list(), df[value_col].to_list()))


def _nutrient_lookup(dir_: Path) -> pl.DataFrame:
    """join_key -> canonical nutrient id, name, unit and rank.

    Two id namespaces coexist in the archives: Foundation and SR Legacy store
    the modern ``nutrient.id`` (1001-2069) in food_nutrient.nutrient_id, while
    FNDDS stores the legacy ``nutrient_nbr`` (< 1000) instead — joining FNDDS
    on ``id`` matches nothing at all. The two ranges don't overlap, so one
    table keyed by both resolves every archive with a single join, and the
    stored nutrient_id is always the modern one.

    join_key stays a float on purpose: 16 nutrient_nbr values are fractional
    (205.2 "Carbohydrate, other" vs 205 "Carbohydrate, by difference"), so
    casting to int would silently merge distinct nutrients.
    """
    empty = pl.DataFrame(
        schema={
            "join_key": pl.Float64,
            "nutrient_id": pl.Int64,
            "nutrient_name": pl.Utf8,
            "unit_name": pl.Utf8,
            "nutrient_rank": pl.Float64,
        }
    )
    path = dir_ / "nutrient.csv"
    if not path.exists():
        return empty
    df = _read_csv(path)
    if not {"id", "name", "unit_name"} <= set(df.columns):
        return empty

    base = df.select(
        _int_col(df, "id").alias("nutrient_id"),
        pl.col("name").alias("nutrient_name"),
        pl.col("unit_name"),
        _float_col(df, "rank").alias("nutrient_rank")
        if "rank" in df.columns
        else pl.lit(None, dtype=pl.Float64).alias("nutrient_rank"),
        _float_col(df, "nutrient_nbr").alias("nbr")
        if "nutrient_nbr" in df.columns
        else pl.lit(None, dtype=pl.Float64).alias("nbr"),
    ).drop_nulls("nutrient_id")

    by_id = base.with_columns(pl.col("nutrient_id").cast(pl.Float64).alias("join_key"))
    by_nbr = base.drop_nulls("nbr").with_columns(pl.col("nbr").alias("join_key"))
    # id rows first so a modern id always wins a collision with a legacy number
    return (
        pl.concat([by_id, by_nbr])
        .drop("nbr")
        .unique(subset=["join_key"], keep="first")
        .select(empty.columns)
    )


def _load_nutrients(dir_: Path, fdc_ids: pl.Series) -> pl.DataFrame:
    """All nutrient amounts (per 100 g) for the given foods, long-form.

    A food can carry several rows for the same nutrient (different derivations
    or acquisition years), so amounts are averaged per (fdc_id, nutrient_id) —
    the same aggregation the old fat-only loader used.
    """
    empty = pl.DataFrame(schema=_NUTRIENT_SCHEMA)
    path = dir_ / "food_nutrient.csv"
    if not path.exists():
        return empty
    lookup = _nutrient_lookup(dir_)
    if lookup.is_empty():
        return empty

    lf = pl.scan_csv(path, infer_schema_length=0)
    if not {"fdc_id", "nutrient_id", "amount"} <= set(lf.collect_schema().names()):
        return empty

    return (
        lf.select(
            pl.col("fdc_id").cast(pl.Float64, strict=False).cast(pl.Int64, strict=False),
            pl.col("nutrient_id").cast(pl.Float64, strict=False).alias("join_key"),
            pl.col("amount").cast(pl.Float64, strict=False),
        )
        .filter(_in_ids(fdc_ids) & pl.col("amount").is_not_null())
        .collect()
        .join(lookup, on="join_key", how="inner")
        .group_by("fdc_id", "nutrient_id")
        .agg(
            pl.col("nutrient_name").first(),
            pl.col("unit_name").first(),
            pl.col("nutrient_rank").first(),
            pl.col("amount").mean(),
        )
        .select(list(_NUTRIENT_SCHEMA))
    )


def _load_portions(dir_: Path, fdc_ids: pl.Series) -> pl.DataFrame:
    """Household measures per food, e.g. 1 "Banana" (Peeled) = 110 g.

    Foundation and SR Legacy describe the unit with measure_unit_id + modifier;
    FNDDS leaves measure_unit_id as 9999 ("undetermined") and puts the text in
    portion_description instead, so both columns are kept.

    Only measures of ONE are ingested, because the app logs quantity x portion
    and cannot use a portion that carries its own count ("2 waffles", "0.12
    pie"). The two archive styles express that differently: Foundation and SR
    Legacy set amount = 1, while FNDDS leaves amount empty and writes the count
    into the text ("1 cup"). Once filtered, amount is always one and is dropped
    rather than stored.
    """
    empty = pl.DataFrame(schema=_PORTION_SCHEMA)
    path = dir_ / "food_portion.csv"
    if not path.exists():
        return empty
    df = _read_csv(path)
    if "fdc_id" not in df.columns:
        return empty

    units = _lookup(dir_, "measure_unit.csv", "name")
    unit_expr = (
        _int_col(df, "measure_unit_id").replace_strict(units, default=None, return_dtype=pl.Utf8)
        if "measure_unit_id" in df.columns
        else pl.lit(None, dtype=pl.Utf8)
    )
    return (
        df.select(
            _int_col(df, "fdc_id").alias("fdc_id"),
            _int_col(df, "seq_num").alias("seq_num") if "seq_num" in df.columns else pl.lit(None, dtype=pl.Int64).alias("seq_num"),
            _float_col(df, "amount").alias("amount"),
            unit_expr.alias("measure_unit"),
            _opt_col(df, "portion_description"),
            _opt_col(df, "modifier"),
            _float_col(df, "gram_weight").alias("gram_weight"),
            _int_col(df, "data_points").alias("data_points") if "data_points" in df.columns else pl.lit(None, dtype=pl.Int64).alias("data_points"),
            _opt_col(df, "footnote"),
        )
        .filter(
            _in_ids(fdc_ids)
            & (
                (pl.col("amount") == 1)
                | (
                    pl.col("amount").is_null()
                    & pl.col("portion_description").str.starts_with("1 ")
                )
            )
        )
        .with_columns(
            # 9999 "undetermined" is a placeholder, not a real unit
            pl.when(pl.col("measure_unit") == "undetermined")
            .then(None)
            .otherwise(pl.col("measure_unit"))
            .alias("measure_unit"),
            # FNDDS fills modifier with its numeric measure code (10205, 90000),
            # not display text; without this it wins the label coalesce below.
            pl.when(pl.col("modifier").str.contains(r"^\d+$"))
            .then(None)
            .otherwise(pl.col("modifier"))
            .alias("modifier"),
        )
        # amount is 1 on every surviving row, so _PORTION_SCHEMA drops it here
        .select(list(_PORTION_SCHEMA))
    )


def _load_attributes(dir_: Path, fdc_ids: pl.Series) -> pl.DataFrame:
    """Free-form per-food attributes (FoodOn ontology names, common names...)."""
    empty = pl.DataFrame(schema=_ATTRIBUTE_SCHEMA)
    path = dir_ / "food_attribute.csv"
    if not path.exists():
        return empty
    df = _read_csv(path)
    if "fdc_id" not in df.columns:
        return empty

    types = _lookup(dir_, "food_attribute_type.csv", "name")
    # Foundation's ontology rows have a blank food_attribute_type_id; resolving
    # to null (rather than dropping them) keeps them in the table.
    type_expr = (
        _int_col(df, "food_attribute_type_id").replace_strict(types, default=None, return_dtype=pl.Utf8)
        if "food_attribute_type_id" in df.columns
        else pl.lit(None, dtype=pl.Utf8)
    )
    return (
        df.select(
            _int_col(df, "fdc_id").alias("fdc_id"),
            _int_col(df, "seq_num").alias("seq_num") if "seq_num" in df.columns else pl.lit(None, dtype=pl.Int64).alias("seq_num"),
            type_expr.alias("attribute_type"),
            _opt_col(df, "name"),
            _opt_col(df, "value"),
        )
        .filter(_in_ids(fdc_ids))
        .select(list(_ATTRIBUTE_SCHEMA))
    )


def _load_input_foods(dir_: Path, fdc_ids: pl.Series) -> pl.DataFrame:
    """Ingredient breakdown. Foundation names the columns ingredient_*, FNDDS
    names them sr_*; SR Legacy ships no input_food.csv at all."""
    empty = pl.DataFrame(schema=_INPUT_FOOD_SCHEMA)
    path = dir_ / "input_food.csv"
    if not path.exists():
        return empty
    df = _read_csv(path)
    if "fdc_id" not in df.columns:
        return empty

    code = "ingredient_code" if "ingredient_code" in df.columns else "sr_code"
    desc = "ingredient_description" if "ingredient_description" in df.columns else "sr_description"
    return (
        df.select(
            _int_col(df, "fdc_id").alias("fdc_id"),
            _int_col(df, "seq_num").alias("seq_num") if "seq_num" in df.columns else pl.lit(None, dtype=pl.Int64).alias("seq_num"),
            _int_col(df, "fdc_of_input_food").alias("fdc_of_input_food") if "fdc_of_input_food" in df.columns else pl.lit(None, dtype=pl.Int64).alias("fdc_of_input_food"),
            _float_col(df, "amount").alias("amount"),
            _opt_col(df, code).alias("ingredient_code"),
            _opt_col(df, desc).alias("ingredient_description"),
            _opt_col(df, "unit"),
            _opt_col(df, "portion_description"),
            _float_col(df, "gram_weight").alias("gram_weight"),
            _opt_col(df, "retention_code"),
        )
        .filter(_in_ids(fdc_ids))
        .select(list(_INPUT_FOOD_SCHEMA))
    )


def _load_metadata(dir_: Path, data_type: str) -> pl.DataFrame:
    """Per-food USDA identifiers from the archive's own metadata table.

    Each archive ships a different column set (NDB number for Foundation/SR
    Legacy, food code + WWEIA number + validity dates for FNDDS), so absent
    fields become typed nulls and every archive returns one uniform schema.
    """
    empty = pl.DataFrame(schema=_METADATA_SCHEMA)
    filename = METADATA_FILES.get(data_type)
    if filename is None or not (dir_ / filename).exists():
        return empty
    df = _read_csv(dir_ / filename)
    if "fdc_id" not in df.columns:
        return empty

    return df.select(
        _int_col(df, "fdc_id").alias("fdc_id"),
        _opt_col(df, "NDB_number").alias("ndb_number"),
        _opt_col(df, "food_code").alias("food_code"),
        _opt_col(df, "wweia_category_number").alias("wweia_category_number"),
        _date_col(df, "start_date").alias("start_date") if "start_date" in df.columns else pl.lit(None, dtype=pl.Date).alias("start_date"),
        _date_col(df, "end_date").alias("end_date") if "end_date" in df.columns else pl.lit(None, dtype=pl.Date).alias("end_date"),
        _opt_col(df, "footnote").alias("usda_footnote"),
    ).select(list(_METADATA_SCHEMA))


def _survey_categories(dir_: Path) -> pl.DataFrame:
    """fdc_id -> WWEIA category description for FNDDS rows.

    FNDDS food.csv rows have no food_category_id; the category lives in
    survey_fndds_food.csv (WWEIA code) + wweia_food_category.csv (labels).
    Column names have shifted slightly across releases, so they are located
    by 'wweia'/'category' substrings rather than hardcoded.
    """
    empty = pl.DataFrame(schema={"fdc_id": pl.Int64, "food_category": pl.Utf8})
    sf_path = dir_ / "survey_fndds_food.csv"
    wc_path = dir_ / "wweia_food_category.csv"
    if not (sf_path.exists() and wc_path.exists()):
        return empty

    sf = _read_csv(sf_path)
    wc = _read_csv(wc_path)

    sf_code = next((c for c in sf.columns if "wweia" in c.lower() and "categ" in c.lower()), None)
    wc_desc = next((c for c in wc.columns if "descri" in c.lower()), None)
    wc_code = next(
        (c for c in wc.columns if "categ" in c.lower() and c != wc_desc), None
    )
    if not (sf_code and wc_code and wc_desc):
        return empty

    sf = sf.select(_int_col(sf, "fdc_id").alias("fdc_id"), _int_col(sf, sf_code).alias("code"))
    wc = wc.select(_int_col(wc, wc_code).alias("code"), pl.col(wc_desc).alias("food_category"))
    return sf.join(wc, on="code", how="left").select("fdc_id", "food_category")


def load_frames(archives: dict[str, Archive], extract_root: Path = config.EXTRACT_DIR) -> dict[str, pl.DataFrame]:
    """Normalize all archives into one frame per table.

    Returns ``{"foods", "nutrients", "portions", "attributes", "input_foods"}``.
    ``foods`` holds one row per food (description, category, USDA metadata);
    the rest are long-form child tables keyed by fdc_id.
    """
    frames: list[pl.DataFrame] = []
    children: dict[str, list[pl.DataFrame]] = {k: [] for k in CHILD_TABLES}
    for data_type, archive in archives.items():
        dir_ = extract_archive(archive, extract_root)

        food = _read_csv(dir_ / "food.csv")
        food = food.select(
            _int_col(food, "fdc_id").alias("fdc_id"),
            pl.col("data_type"),
            pl.col("description"),
            _int_col(food, "food_category_id").alias("food_category_id")
            if "food_category_id" in food.columns
            else pl.lit(None, dtype=pl.Int64).alias("food_category_id"),
            _date_col(food, "publication_date").alias("publication_date")
            if "publication_date" in food.columns
            else pl.lit(None, dtype=pl.Date).alias("publication_date"),
        ).filter(
            # each archive should only contain its own type; enforce anyway.
            # The Foundation archive really does need this: only ~469 of its
            # 88k food.csv rows are foundation_food, the rest are sample and
            # market-acquisition provenance records.
            pl.col("data_type") == data_type
        )

        cat_path = dir_ / "food_category.csv"
        if cat_path.exists():
            cats = _read_csv(cat_path)
            cats = cats.select(
                _int_col(cats, "id").alias("food_category_id"),
                pl.col("description").alias("food_category"),
            )
            food = food.join(cats, on="food_category_id", how="left")
        else:
            food = food.with_columns(pl.lit(None, dtype=pl.Utf8).alias("food_category"))

        if data_type == "survey_fndds_food":
            wweia = _survey_categories(dir_)
            if not wweia.is_empty():
                food = (
                    food.join(wweia.rename({"food_category": "wweia_category"}), on="fdc_id", how="left")
                    .with_columns(
                        pl.coalesce(pl.col("food_category"), pl.col("wweia_category")).alias("food_category")
                    )
                    .drop("wweia_category")
                )

        food = food.join(_load_metadata(dir_, data_type), on="fdc_id", how="left")

        # Child tables are restricted to the foods that survived the data_type
        # filter above, otherwise Foundation drags in ~150k provenance rows.
        ids = food["fdc_id"].drop_nulls().unique()
        nutrients = _load_nutrients(dir_, ids)
        children["nutrients"].append(nutrients)
        children["portions"].append(_load_portions(dir_, ids))
        children["attributes"].append(_load_attributes(dir_, ids))
        children["input_foods"].append(_load_input_foods(dir_, ids))

        # foods.fat_g is just one row of the nutrient frame, so reuse it rather
        # than scanning the (up to 35 MB) food_nutrient.csv a second time.
        fat = nutrients.filter(pl.col("nutrient_id") == config.FAT_NUTRIENT_ID).select(
            "fdc_id", pl.col("amount").alias("fat_g")
        )
        food = food.join(fat, on="fdc_id", how="left")

        frames.append(
            food.select(
                "fdc_id",
                "data_type",
                "food_category",
                "description",
                "publication_date",
                "ndb_number",
                "food_code",
                "wweia_category_number",
                "start_date",
                "end_date",
                "usda_footnote",
                pl.col("fat_g").cast(pl.Float64) if "fat_g" in food.columns else pl.lit(None, dtype=pl.Float64).alias("fat_g"),
                pl.lit(archive.version).alias("source_version"),
            )
        )

    foods = (
        pl.concat(frames)
        .filter(pl.col("fdc_id").is_not_null() & pl.col("description").is_not_null())
        .unique(subset=["fdc_id"], keep="first")
        .sort("fdc_id")
    )
    # keep child rows referentially consistent with the deduped foods frame
    kept = foods.select("fdc_id")
    out = {"foods": foods}
    for name in CHILD_TABLES:
        out[name] = pl.concat(children[name]).join(kept, on="fdc_id", how="semi").sort("fdc_id")
    return out


def run(raw_dir: Path = config.RAW_DIR) -> dict[str, pl.DataFrame]:
    """Stage 1 driver: locate archives, extract, normalize. Pure read side —
    persistence happens in store.upsert_ingest / upsert_ingest_children so
    DuckDB stays the single source of truth."""
    archives = ensure_archives(raw_dir)
    return load_frames(archives)
