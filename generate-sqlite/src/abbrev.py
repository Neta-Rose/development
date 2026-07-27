"""Stage 2 — Deterministic abbreviation expansion.

Order-preserving, non-destructive, idempotent. USDA descriptions carry
cryptic whole-token abbreviations ("Yogurt, NS as to type of milk",
"Frozen yogurt, NFS") that neither an LLM nor an embedder resolves
consistently. Expanding them from a fixed dictionary is deterministic,
logged and reversible — strictly better than paying a model to guess once
per call.

Expansion is applied to ``description`` in place. It is idempotent (expanded
text has no abbreviations left to match), every substitution is recorded in
``cleanup_log``, and the raw USDA text is always recoverable by re-running
ingest against ``data/raw/``.

Unicode, whitespace and casing normalization used to live here and were
removed deliberately: measured over the 13,694-row corpus they rewrote 2,100+
rows that no consumer could perceive, while the casing pass lowercased proper
nouns ("Goya Crackers" -> "goya crackers") and destroyed the brand signal on
~1,000 rows that miss ``config.BRAND_TOKENS``.

``fat_percentage`` is extracted HERE, by regex, as a deterministic rule. It is
context for the pipeline, never an LLM output.
"""
from __future__ import annotations

import re
from dataclasses import dataclass, field

import polars as pl

from . import config

_ABBREV_COMPILED = [
    (name, re.compile(pattern, re.IGNORECASE if ci else 0), repl)
    for name, pattern, repl, ci in config.ABBREVIATION_RULES
]

# fat_percentage regexes, in priority order: milkfat > fat > lean.
RE_MILKFAT = re.compile(r"(\d+(?:\.\d+)?)\s*%\s*(?:milk\s*fat|milkfat)", re.IGNORECASE)
RE_FAT = re.compile(r"(\d+(?:\.\d+)?)\s*%\s*fat\b", re.IGNORECASE)
RE_LEAN = re.compile(r"(\d+(?:\.\d+)?)\s*%\s*lean\b", re.IGNORECASE)

# Used by the Stage 5 cross-check: a non-null fat_percentage requires one of
# these tokens in the source text.
FAT_TOKEN_RE = re.compile(r"%\s*(?:lean|fat|milk\s*fat|milkfat)", re.IGNORECASE)


@dataclass
class ExpansionResult:
    description: str
    fat_percentage: float | None
    # (rule, before_fragment, after_fragment) for every substitution applied
    substitutions: list[tuple[str, str, str]] = field(default_factory=list)


def _guard_preserved_tokens(before: str, after: str, rule: str) -> None:
    """Fail loudly if a rule dropped a preparation/nutrition token.

    Expansion never removes words, but this guard makes it impossible for a
    future dictionary entry to silently strip whitelisted tokens like "raw",
    "drained" or "without salt".
    """
    before_tokens = set(re.findall(r"[a-z]+", before.lower()))
    after_tokens = set(re.findall(r"[a-z]+", after.lower()))
    lost = (before_tokens & config.PRESERVE_TOKENS) - after_tokens
    if lost:
        raise ValueError(
            f"expansion rule {rule!r} dropped protected token(s) {sorted(lost)}: "
            f"{before!r} -> {after!r}"
        )


def expand_abbreviations(text: str) -> tuple[str, list[tuple[str, str, str]]]:
    """Fixed, whole-token dictionary expansion (see config.ABBREVIATION_RULES)."""
    subs: list[tuple[str, str, str]] = []
    out = text
    for name, pattern, repl in _ABBREV_COMPILED:
        def _sub(m: re.Match, _name=name, _repl=repl) -> str:
            subs.append((f"abbrev:{_name}", m.group(0), _repl.strip()))
            return _repl
        out = pattern.sub(_sub, out)
    # replacements like "w/ " -> "with " can introduce double spaces
    out = re.sub(r"\s+", " ", out).strip()
    return out, subs


def extract_fat_percentage(text: str) -> float | None:
    """Deterministic fat % from '% milkfat' / '% fat' / '% lean'.

    Explicit fat/milkfat percentages win. A lean-only declaration
    ("95% lean") is converted to fat share as 100 - lean, the standard
    complement on US meat labels. Null when no pattern matches.
    """
    m = RE_MILKFAT.search(text) or RE_FAT.search(text)
    if m:
        return float(m.group(1))
    m = RE_LEAN.search(text)
    if m:
        return round(100.0 - float(m.group(1)), 2)
    return None


def expand_description(description: str) -> ExpansionResult:
    """Full deterministic pipeline for one description. Idempotent.

    The fat regexes are whitespace-tolerant and case-insensitive, so
    expansion cannot change what they match (verified across the corpus:
    0/13694 rows differ) — no pre-expansion fallback is needed.
    """
    out, subs = expand_abbreviations(description)
    _guard_preserved_tokens(description, out, "abbreviations")
    return ExpansionResult(
        description=out,
        fat_percentage=extract_fat_percentage(out),
        substitutions=subs,
    )


def expand_frame(df: pl.DataFrame) -> tuple[pl.DataFrame, pl.DataFrame]:
    """Expand every row of a foods frame.

    Returns ``(expanded_df, log_df)`` where expanded_df has ``fdc_id``,
    ``description`` and ``fat_percentage``, and log_df has one row per
    substitution applied.
    """
    expanded_rows: list[dict] = []
    log_rows: list[dict] = []
    for fdc_id, description in df.select("fdc_id", "description").iter_rows():
        result = expand_description(description)
        expanded_rows.append(
            {
                "fdc_id": fdc_id,
                "description": result.description,
                "fat_percentage": result.fat_percentage,
            }
        )
        for rule, before, after in result.substitutions:
            log_rows.append(
                {"fdc_id": fdc_id, "rule": rule, "old_text": before, "new_text": after}
            )
    expanded_df = pl.DataFrame(
        expanded_rows,
        schema={
            "fdc_id": pl.Int64,
            "description": pl.Utf8,
            "fat_percentage": pl.Float64,
        },
    )
    log_df = pl.DataFrame(
        log_rows,
        schema={"fdc_id": pl.Int64, "rule": pl.Utf8, "old_text": pl.Utf8, "new_text": pl.Utf8},
    )
    return expanded_df, log_df


def token_frequencies(df: pl.DataFrame, column: str = "description") -> pl.DataFrame:
    """Rank corpus tokens by frequency.

    Diagnostic used to build the abbreviation dictionary empirically: run
    this, eyeball the cryptic high-frequency tokens, and add mappings to
    config.ABBREVIATION_RULES.
    """
    return (
        df.select(pl.col(column).str.to_lowercase().str.extract_all(r"[a-z/&']+"))
        .explode(column)
        .rename({column: "token"})
        .drop_nulls()
        .group_by("token")
        .len(name="count")
        .sort("count", descending=True)
    )


def run(con) -> dict:
    """Stage 2 driver: read foods from DuckDB, expand, persist, log.

    Skips nothing on the compute side (expansion is cheap, deterministic and
    idempotent) but the store layer never writes to human-verified rows.
    """
    from . import store  # local import to avoid a cycle at module load

    df = store.load_foods(con, columns=["fdc_id", "description"])
    if df.is_empty():
        return {"expanded": 0, "substitutions": 0}
    expanded_df, log_df = expand_frame(df)
    written = store.update_expansions(con, expanded_df, log_df)
    return {"expanded": written, "substitutions": len(log_df)}
