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
- `../database/MIGRATION_MERGED_FOODS.md` — the app-side migration for the Stage 6b
  export (Flutter/Drift). One doc per breaking-ish catalog change; the catalog itself
  is always replaced wholesale, so these are query migrations, not schema ones.
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
| 4 / 4b / 4c | `enrich.py` | `Enricher`, `CommonnessEnricher`, `KeywordsEnricher` |
| 5 routing | `store.py` | confidence → `auto_approved` / `needs_review` |
| 6 review | `store.py` | `review_queue` / `apply_human_review` |
| 6b merge | `merge.py` | macro-ratio dedup into `merged_foods` |
| 7 export | `appdb.py` | builds `app_*` tables, writes `../database/foods.sqlite` + `data/log.sqlite` |

## Invariants that constrain edits

- **DuckDB (`data/foods.duckdb`) is the only source of truth.** In-memory frames are
  transient; every stage reads from and writes back to it.
- **No automated pass may write a row with `human_verified = true`.** Enforced in the
  WHERE clause of every automated UPDATE in `store.py`. New write paths must carry it.
- **Every write appends to `audit_log`** via `store._audit`.
- **`data_type` and `fat_percentage` are never LLM outputs** — verbatim and regex.
- Every stage is **resumable and idempotent**: re-running skips completed rows.
  `appdb.build` is fully derived — drop the `app_*` tables and re-run.

## Two non-obvious mechanisms

**The DuckDB file lock is held only for writes.** `store.connect` opens an in-memory
root and *ATTACHes* the file, because an open connection holds an exclusive
process-wide lock for as long as the file is attached — which would lock out a DuckDB
shell for the length of a whole enrichment run. `store.unlocked(con)` detaches for the
body, `store.locked(con, path)` takes it back for a flush; `enrich.py` wraps its run in
the former and each batched write in the latter. Long-running work that touches no
tables belongs inside `unlocked`.

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
