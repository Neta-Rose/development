# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
uv sync                                  # install (Python 3.11+, uv-managed)
uv run marimo edit notebook.py           # run the pipeline (the only entry point)
uv run pytest                            # 57 offline tests, no network/API key
uv run pytest tests/test_pipeline.py::test_human_verified_lock   # one test
```

`OPENROUTER_API_KEY` in `.env` is the only required secret (Stage 8 additionally
wants `SUPABASE_URL` / `SUPABASE_SERVICE_KEY`). No linter is configured.

## Where things live

- `README.md` — the design record: why each stage exists, what was measured, what
  was deliberately removed. Read the relevant section before changing a stage; most
  "obvious improvements" here are things that were tried and reverted with numbers.
- `../database/APP_DATABASE.md` — the consumer-facing reference for the two SQLite
  schemas, and the Flutter app's own schema reference. Keep it in sync when
  `appdb.py` schemas change. It also records the app's search tuning, so read a
  section before rewriting it — the queries there are the ones the app ships.
- `../database/MIGRATION_MERGED_ITEMS.md` — the app-side migration for the current
  catalog shape (Flutter/Drift). One doc per breaking-ish catalog change; the catalog
  itself is always replaced wholesale, so these are query migrations, not schema ones.
  `MIGRATION_MERGED_FOODS.md` is its superseded predecessor, kept as the record of the
  first grouping attempt.
- `notebook.py` — thin marimo driver, **no logic**. Each `## Stage N` heading is a
  run-button-gated call into one `src/` module's `run()`.
- `src/config.py` — the single tuning surface. Thresholds, model, dictionaries,
  brand list, nutrient map. Adding a key to `APP_NUTRIENTS` propagates to the wide
  table, its DDL, and the recipe roll-up automatically.

## Stage map

| Stage | Module | Notes |
| --- | --- | --- |
| 1 ingest | `ingest.py` | scrapes FDC download page; falls back to newest zip in `data/raw/` |
| 2 abbrev | `abbrev.py` | whole-token expansion in place + `fat_percentage` regex |
| 3 brand | `brand_detect.py` | SR Legacy only; needs source casing intact |
| 3b-1 canon | `canon.py` | LLM, ~40 foods/request → `foods.base_name` / `food_kind` / `prep_label` |
| 3b cluster | `cluster.py` | `GROUP BY (base_key, food_kind)` → `merged_foods` / `merged_preps`; no LLM, no thresholds |
| 4 enrich | `enrich.py` | one request per **item**, presentation only (name/emoji/keywords/commonness) |
| 5 routing | `store.py` | confidence → `auto_approved` / `needs_review` |
| 6 review | `store.py` | `review_queue` / `apply_human_review`, keyed on `merged_food_id` |
| 7 export | `appdb.py` | builds `app_*` tables, writes `../database/foods.sqlite` + `data/log.sqlite` |

## Invariants that constrain edits

- **DuckDB (`data/foods.duckdb`) is the only source of truth.** In-memory frames are
  transient; every stage reads from and writes back to it.
- **No automated pass may write a row with `human_verified = true`.** Enforced in the
  WHERE clause of every automated UPDATE in `store.py`. New write paths must carry it.
  The lock lives on **`merged_foods`** — that is where naming and review moved when
  enrichment became per-group. Nothing on `foods` is human-authored, Stage 3b-1's
  identity columns included: they are facts about a row, re-derivable by nulling
  `base_name` and re-running.
- **Every write appends to `audit_log`** via `store._audit`. `write_clusters` is the
  one place that audits *transitions* only (created / dissolved / membership changed),
  because a full trail would be 8.3k no-op rows per run.
- **`data_type`, `fat_percentage` and `variable_fat` are never LLM outputs** —
  verbatim, regex, and measured over the group. `variable_fat` has to be deterministic
  because the preparation split changes basis on it and runs before the LLM.
- **Identity is a key, never a threshold.** `foods.base_key` + `food_kind` IS the
  clustering; `cluster.base_key()` is the one normalization and `store.apply_canonicalization`
  derives it on write so the writer and the reader cannot drift. Macros decide
  preparations and nothing else — the two thresholds that used to decide identity were
  removed with measurements, and the README's *Clustering* section is that record. Do
  not reintroduce a similarity score here; fix the canon.py prompt instead.
- Every stage is **resumable and idempotent**: re-running skips completed rows.
  `appdb.build` is fully derived — drop the `app_*` tables and re-run.
- **Stage 3b must never destroy Stage 4's output.** `merged_foods` holds a whole
  enrichment run, so `write_clusters` upserts: unchanged items are left alone, items
  whose `member_key` moved go back to `review_status='pending'` but **keep** their
  name, and dissolved items are audited on the way out. The `DELETE`-and-refill this
  replaced was safe only while the table was purely derived. `merged_preps` IS refilled
  wholesale — `prep_type` comes from `prep_label` now, so nothing on it is LLM output.

## Two non-obvious mechanisms

**The DuckDB file lock is held only for writes.** `store.connect` opens an in-memory
root and *ATTACHes* the file, because an open connection holds an exclusive
process-wide lock for as long as the file is attached — which would lock out a DuckDB
shell for the length of a whole enrichment run. `store.unlocked(con)` detaches for the
body, `store.locked(con, path)` takes it back for a flush; `enrich._LLMPass` wraps its
run in the former and each batched write in the latter, for both LLM stages. Long-running
work that touches no tables belongs inside `unlocked`.

**Both LLM stages share one transport.** `enrich._LLMPass` owns pacing, tenacity backoff,
the `response_format`→forced-tool fallback, usage accounting and the flush cycle;
`Enricher` and `canon.Canonicalizer` supply only four hooks — which rows are candidates,
what a request looks like, how the answer validates, what gets written. A third pass
subclasses it rather than copying it.

**Schema changes go through `store.init_db`**, which runs the idempotent `_migrate_*`
functions against existing databases before checkpointing. That CHECKPOINT is
load-blocking, not cosmetic: DuckDB cannot replay a WAL containing an ALTER on a table
with a function-valued DEFAULT, and a stranded WAL costs a whole run.

## marimo conventions

Cells declare dependencies as function parameters and return a tuple of what they
export — editing a cell means keeping both in step. Side-effecting stages are gated
behind `mo.ui.run_button` + `mo.stop(not button.value, ...)` so reactivity can never
auto-fire ~15k API calls; keep that pattern for any new stage. `auto_reload = "lazy"`
(pyproject) reloads edited `src/` modules but marks dependent cells stale rather than
re-running them. Skills for authoring marimo notebooks are vendored in
`.agents/skills/`.
