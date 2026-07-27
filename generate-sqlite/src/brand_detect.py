"""Stage 3 — SR Legacy brand-in-description detection.

SR Legacy has no brand field or flag; brand names live only inside the
description text ("Cereals ready-to-eat, KELLOGG, KELLOGG'S CORN FLAKES",
"McDONALD'S, Big Mac"). Rows are flagged with ``brand_flagged`` via:

1. a maintained brand-token list (config.BRAND_TOKENS), and
2. an ALL-CAPS proper-noun heuristic (SR Legacy shouts brand names).

The ALL-CAPS heuristic needs the source casing intact. Stage 2 used to
lowercase it (and was measured destroying the brand signal on ~1000 rows
that miss BRAND_TOKENS); it now only expands abbreviations, which leaves
casing untouched, so this stage is order-independent.

Flagged rows are down-ranked/excluded from the generic catalog and force-
routed to needs_review. The common path is pure rules; only long-tail
ambiguous cases would ever warrant an LLM (deliberately not implemented —
rule coverage on SR Legacy is high and rules are free and deterministic).
"""
from __future__ import annotations

import re

import polars as pl

from . import config

_BRAND_RES = [
    re.compile(rf"(?<!\w){re.escape(tok.strip())}(?!\w)", re.IGNORECASE)
    for tok in config.BRAND_TOKENS
]

# tokens of >=3 letters (apostrophes allowed) that are fully uppercase
_ALLCAPS_TOKEN_RE = re.compile(r"[A-Z][A-Z'\.]{2,}")


def detect_brand(description: str, data_type: str) -> bool:
    """True when an SR Legacy description looks branded. Others: always False."""
    if data_type != "sr_legacy_food":
        return False
    text = description
    if any(p.search(text) for p in _BRAND_RES):
        return True
    for token in _ALLCAPS_TOKEN_RE.findall(text):
        bare = token.strip(".'")
        if len(bare) >= 3 and bare not in config.ALLCAPS_WHITELIST:
            return True
    return False


def flag_frame(df: pl.DataFrame) -> pl.DataFrame:
    """Compute brand_flagged for a foods frame (fdc_id, data_type, description)."""
    flags = [
        {"fdc_id": fdc_id, "brand_flagged": detect_brand(desc, dt)}
        for fdc_id, dt, desc in df.select(
            "fdc_id", "data_type", "description"
        ).iter_rows()
    ]
    return pl.DataFrame(flags, schema={"fdc_id": pl.Int64, "brand_flagged": pl.Boolean})


def run(con) -> dict:
    """Stage 3 driver: flag SR Legacy rows in DuckDB."""
    from . import store

    df = store.load_foods(con, columns=["fdc_id", "data_type", "description"])
    if df.is_empty():
        return {"scanned": 0, "flagged": 0}
    flags = flag_frame(df)
    written = store.update_brand_flags(con, flags)
    return {
        "scanned": len(flags),
        "flagged": int(flags["brand_flagged"].sum()),
        "updated": written,
    }
