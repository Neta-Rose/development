# CLAUDE.md

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
  derives it on write so the writer and the reader cannot drift. The `food_kind` half is
  read **per identity, not per row**: where one `base_key`'s records disagree,
  `cluster._voted_kinds` takes the majority (ties to `ingredient`) and declines on the
  identities `cluster.spelling_splits` flags, which is the gate that keeps a token-sort
  collision from merging. It is derived on every run and **never written** — the stored
  `food_kind` stays what Stage 3b-1 said about that one record. Macros decide
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


**Schema changes go through `store.init_db`**, which runs the idempotent `_migrate_*`
functions against existing databases before checkpointing. That CHECKPOINT is
load-blocking, not cosmetic: DuckDB cannot replay a WAL containing an ALTER on a table
with a function-valued DEFAULT, and a stranded WAL costs a whole run.