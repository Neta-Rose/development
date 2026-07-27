import marimo

__generated_with = "0.23.14"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import duckdb

    return (mo,)


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    # FDC generic-food enrichment pipeline

    Ingests **Foundation / SR Legacy / FNDDS** foods from USDA FoodData
    Central, cleans descriptions deterministically, enriches them with an
    LLM via OpenRouter, and routes low-confidence rows to the human-review
    queue below.

    All state lives in `data/foods.duckdb` — this notebook is a thin
    driver over the modules in `src/`. Every expensive or side-effecting
    stage is gated behind a run button so marimo's reactivity can never
    auto-fire ~15k API calls.

    Run order: **Ingest → Cleanup → Brand flags → Sample enrich → Full
    enrich → Review → Export**. Every stage is resumable and idempotent;
    human-verified rows are never overwritten by re-runs.
    """)
    return


@app.cell
def _():
    import asyncio
    import logging
    import sys
    from pathlib import Path

    PROJECT_ROOT = Path(__file__).resolve().parent
    if str(PROJECT_ROOT) not in sys.path:
        sys.path.insert(0, str(PROJECT_ROOT))

    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(name)s: %(message)s",
        filename=PROJECT_ROOT / "enrich.log",
    )

    from dotenv import load_dotenv

    load_dotenv(PROJECT_ROOT / ".env")

    from src import abbrev, appdb, brand_detect, config, enrich, ingest, merge, store

    return abbrev, appdb, asyncio, brand_detect, config, enrich, ingest, merge, store


@app.cell
def _(config, store):
    con = store.connect(config.DB_PATH)
    store.init_db(con)
    return (con,)


@app.cell
def _(mo):
    mo.md(r"""
    ## Stage 1 — Ingest FDC archives
    """)
    return


@app.cell
def _(mo):
    ingest_button = mo.ui.run_button(label="⬇️ Run ingest (downloads FDC archives)")
    ingest_button
    return (ingest_button,)


@app.cell
def _(con, config, ingest, ingest_button, mo, store):
    mo.stop(not ingest_button.value, mo.md("_Click to download + load Foundation, SR Legacy and FNDDS._"))
    _frames = ingest.run(raw_dir=config.RAW_DIR)
    ingest_counts = store.upsert_ingest(con, _frames["foods"])
    child_counts = store.upsert_ingest_children(con, _frames)
    mo.md(
        f"**Ingest done.** {len(_frames['foods']):,} foods normalized — "
        f"inserted {ingest_counts['inserted']:,}, updated {ingest_counts['updated']:,}, "
        f"human-verified rows skipped {ingest_counts['locked_skipped']:,}.\n\n"
        + " · ".join(f"{t} {n:,}" for t, n in child_counts.items())
    )
    return


@app.cell
def _():
    return


@app.cell
def _(con, mo):
    _df = mo.sql(
        f"""
        SELECT * FROM "foods" LIMIT 100
        """,
        engine=con
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 2 — Deterministic abbreviation expansion
    """)
    return


@app.cell
def _(mo):
    expand_button = mo.ui.run_button(label="🧹 Run abbreviation expansion")
    expand_button
    return (expand_button,)


@app.cell
def _(abbrev, con, expand_button, mo):
    mo.stop(not expand_button.value, mo.md("_Click to expand abbreviations and extract fat % (writes to DuckDB)._"))
    expand_counts = abbrev.run(con)
    mo.md(
        f"**Expansion done.** {expand_counts['expanded']:,} rows updated, "
        f"{expand_counts['substitutions']:,} substitutions logged to `cleanup_log`."
    )
    return


@app.cell
def _(con, mo):
    _df = mo.sql(
        f"""
        SELECT * FROM "cleanup_log" LIMIT 100
        """,
        engine=con
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ### Corpus token diagnostics (read-only)

    The abbreviation dictionary in `config.ABBREVIATION_RULES` was built
    empirically: rank corpus tokens by frequency and map the cryptic
    high-frequency ones. Use this table to spot new candidates.
    """)
    return


@app.cell
def _(mo):
    tokens_button = mo.ui.run_button(label="🔤 Compute token frequencies")
    tokens_button
    return (tokens_button,)


@app.cell
def _(abbrev, con, mo, store, tokens_button):
    mo.stop(not tokens_button.value, mo.md("_Click to tokenize the corpus (read-only)._"))
    _foods = store.load_foods(con, columns=["fdc_id", "description"])
    token_freq = abbrev.token_frequencies(_foods, "description")
    mo.ui.table(token_freq.head(1000), selection=None)
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 3 — SR Legacy brand detection
    """)
    return


@app.cell
def _(mo):
    brand_button = mo.ui.run_button(label="🏷️ Run brand detection")
    brand_button
    return (brand_button,)


@app.cell
def _(brand_button, brand_detect, con, mo):
    mo.stop(not brand_button.value, mo.md("_Click to flag SR Legacy rows with brand names in the description._"))
    brand_counts = brand_detect.run(con)
    mo.md(
        f"**Brand detection done.** {brand_counts['flagged']:,} of "
        f"{brand_counts['scanned']:,} rows flagged ({brand_counts['updated']:,} changed)."
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 4 — LLM enrichment (OpenRouter)

    **Always run the sample first.** It processes ~200 rows, measures
    token usage and latency, and extrapolates cost for the full corpus
    before you commit to it. Both runs are resumable: completed rows are
    skipped, human-verified rows are never re-enriched.
    """)
    return


@app.cell
def _(config, mo):
    model_text = mo.ui.text(
        value=config.MODEL, full_width=True, label="Model (OpenRouter slug)",
    )
    reasoning_text = mo.ui.text(
        value="", label="Reasoning effort (low/medium/high — blank = none)",
    )
    concurrency_slider = mo.ui.slider(
        1, 64, value=config.CONCURRENCY, show_value=True,
        label="concurrency (in-flight requests)",
    )
    mo.vstack([model_text, reasoning_text, concurrency_slider])
    return concurrency_slider, model_text, reasoning_text


@app.cell
def _(model_text, reasoning_text):
    # Blank reasoning box -> disabled; any value is passed as the effort level.
    _eff = reasoning_text.value.strip()
    enrich_model = model_text.value.strip()
    enrich_reasoning = {"effort": _eff} if _eff else {"enabled": False}
    return enrich_model, enrich_reasoning


@app.cell
def _(mo):
    sample_button = mo.ui.run_button(label="🧪 Run sample enrichment (~200 rows)")
    sample_button
    return (sample_button,)


@app.cell
async def _(
    con,
    concurrency_slider,
    config,
    enrich,
    enrich_model,
    enrich_reasoning,
    mo,
    sample_button,
    store,
):
    mo.stop(not sample_button.value, mo.md("_Click to enrich a small sample and estimate full-run cost._"))

    _seen = [0]  # d is cumulative and throttled; the bar wants a delta

    def _sample_progress(d, t, stats, elapsed):
        tok_s = (stats.prompt_tokens + stats.completion_tokens) / elapsed if elapsed else 0
        _step, _seen[0] = d - _seen[0], d
        _bar.update(
            increment=_step,
            subtitle=f"{tok_s:,.0f} tok/s · ${stats.est_cost_usd:.4f} · {stats.failed} failed",
        )

    with mo.status.progress_bar(total=config.SAMPLE_SIZE, title="Enriching sample") as _bar:
        sample_stats = await enrich.run(
            con, limit=config.SAMPLE_SIZE,
            model=enrich_model, reasoning=enrich_reasoning,
            concurrency=concurrency_slider.value,
            progress_cb=_sample_progress,
        )
    _remaining = store.count_enrichment_candidates(con)
    _proj = sample_stats.estimate_full_run(_remaining)
    mo.md(
        f"""
        **Sample done** ({sample_stats.succeeded}/{sample_stats.requested} ok,
        {sample_stats.failed} failed, {sample_stats.auto_approved} auto-approved,
        {sample_stats.needs_review} to review) in {sample_stats.elapsed_s:.0f}s.

        Tokens: {sample_stats.prompt_tokens:,} prompt / {sample_stats.completion_tokens:,}
        completion → **${sample_stats.est_cost_usd:.4f}** for the sample.

        Prompt cache: **{sample_stats.cache_hit_rate:.0%}** of input served from cache
        ({sample_stats.cached_tokens:,} tokens). Reasoning tokens billed:
        **{sample_stats.reasoning_tokens:,}** (must be 0).

        Projection for the remaining {_proj.get('remaining_rows', 0):,} rows:
        **~${_proj.get('est_cost_usd', 0)}**, ~{_proj.get('est_wall_clock_min', 0)} min
        at {config.REQUESTS_PER_MINUTE or 'unpaced'} req/min, concurrency
        {concurrency_slider.value}.
        """
        + ("\n\n⚠️ Errors:\n" + "\n".join(sample_stats.errors[:10]) if sample_stats.errors else "")
    )
    return


@app.cell
def _(mo):
    full_button = mo.ui.run_button(label="🚀 Run FULL enrichment (spends real money)")
    full_button
    return (full_button,)


@app.cell(hide_code=True)
async def _(
    con,
    concurrency_slider,
    enrich,
    enrich_model,
    enrich_reasoning,
    full_button,
    mo,
    store,
):
    mo.stop(not full_button.value, mo.md("_Click to enrich every remaining candidate row._"))
    _todo = store.count_enrichment_candidates(con)

    _seen = [0]  # d is cumulative and throttled; the bar wants a delta

    def _full_progress(d, t, stats, elapsed):
        tok_s = (stats.prompt_tokens + stats.completion_tokens) / elapsed if elapsed else 0
        _step, _seen[0] = d - _seen[0], d
        _bar.update(
            increment=_step,
            subtitle=f"{tok_s:,.0f} tok/s · ${stats.est_cost_usd:.4f} · {stats.failed} failed",
        )

    with mo.status.progress_bar(total=_todo, title="Enriching") as _bar:
        full_stats = await enrich.run(
            con, limit=None,
            model=enrich_model, reasoning=enrich_reasoning,
            concurrency=concurrency_slider.value,
            progress_cb=_full_progress,
        )
    mo.md(
        f"""
        **Full run done** ({full_stats.succeeded}/{full_stats.requested} ok,
        {full_stats.failed} failed, {full_stats.auto_approved} auto-approved,
        {full_stats.needs_review} routed to review) in
        {full_stats.elapsed_s / 60:.1f} min —
        **${full_stats.est_cost_usd:.2f}** actual token cost.
        (Queue before run: {_todo:,} rows.)
        """
        + ("\n\n⚠️ Errors (first 10):\n" + "\n".join(full_stats.errors[:10]) if full_stats.errors else "")
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 4b — Commonness score (separate LLM pass)

    Rates every food 0–1 on how commonly it is eaten and how likely it is
    to be in an ordinary kitchen (eggs ≈ 1, parmesan ≈ 0.4, turtle meat
    ≈ 0.05) into `foods.commonness`. Independent of Stage 4: its own short
    prompt, its own queue (rows where `commonness IS NULL`), and it never
    touches names or emoji. Uses the model / concurrency set above.
    """)
    return


@app.cell
def _(mo):
    commonness_button = mo.ui.run_button(label="🥚 Run commonness pass (spends real money)")
    commonness_button
    return (commonness_button,)


@app.cell(hide_code=True)
async def _(
    commonness_button,
    con,
    concurrency_slider,
    enrich,
    enrich_model,
    enrich_reasoning,
    mo,
    store,
):
    mo.stop(not commonness_button.value, mo.md("_Click to score every unscored row._"))
    _todo = store.count_enrichment_candidates(con, enrich.CommonnessEnricher.candidate_where)

    _seen = [0]  # d is cumulative and throttled; the bar wants a delta

    def _commonness_progress(d, t, stats, elapsed):
        tok_s = (stats.prompt_tokens + stats.completion_tokens) / elapsed if elapsed else 0
        _step, _seen[0] = d - _seen[0], d
        _bar.update(
            increment=_step,
            subtitle=f"{tok_s:,.0f} tok/s · ${stats.est_cost_usd:.4f} · {stats.failed} failed",
        )

    with mo.status.progress_bar(total=_todo, title="Scoring commonness") as _bar:
        commonness_stats = await enrich.run(
            con, limit=None,
            model=enrich_model, reasoning=enrich_reasoning,
            concurrency=concurrency_slider.value,
            progress_cb=_commonness_progress,
            enricher_cls=enrich.CommonnessEnricher,
        )
    mo.md(
        f"""
        **Commonness pass done** ({commonness_stats.succeeded:,}/{commonness_stats.requested:,} ok,
        {commonness_stats.failed} failed) in {commonness_stats.elapsed_s / 60:.1f} min —
        **${commonness_stats.est_cost_usd:.2f}** actual token cost.
        Failed rows keep `commonness = NULL` and are picked up by the next run.
        """
        + ("\n\n⚠️ Errors (first 10):\n" + "\n".join(commonness_stats.errors[:10])
           if commonness_stats.errors else "")
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 4c — Search keywords (separate LLM pass)

    Generates 6–12 search terms per food — synonyms and regional names,
    the core ingredients of a dish, cuisine/origin, meal occasion — into
    `foods.keywords`. Independent of Stages 4 and 4b: its own prompt, its
    own queue (rows where `keywords IS NULL`), and it touches nothing else.
    Stage 7 appends them to the `aka` column of the app's FTS index, so
    "fettuccine" or "italian" finds an alfredo pasta. Uses the model /
    concurrency set above.
    """)
    return


@app.cell
def _(mo):
    keywords_button = mo.ui.run_button(label="🔎 Run keywords pass (spends real money)")
    keywords_button
    return (keywords_button,)


@app.cell(hide_code=True)
async def _(
    con,
    concurrency_slider,
    enrich,
    enrich_model,
    enrich_reasoning,
    keywords_button,
    mo,
    store,
):
    mo.stop(not keywords_button.value, mo.md("_Click to add keywords to every row without them._"))
    _todo = store.count_enrichment_candidates(con, enrich.KeywordsEnricher.candidate_where)

    _seen = [0]  # d is cumulative and throttled; the bar wants a delta

    def _keywords_progress(d, t, stats, elapsed):
        tok_s = (stats.prompt_tokens + stats.completion_tokens) / elapsed if elapsed else 0
        _step, _seen[0] = d - _seen[0], d
        _bar.update(
            increment=_step,
            subtitle=f"{tok_s:,.0f} tok/s · ${stats.est_cost_usd:.4f} · {stats.failed} failed",
        )

    with mo.status.progress_bar(total=_todo, title="Generating keywords") as _bar:
        keywords_stats = await enrich.run(
            con, limit=None,
            model=enrich_model, reasoning=enrich_reasoning,
            concurrency=concurrency_slider.value,
            progress_cb=_keywords_progress,
            enricher_cls=enrich.KeywordsEnricher,
        )
    mo.md(
        f"""
        **Keywords pass done** ({keywords_stats.succeeded:,}/{keywords_stats.requested:,} ok,
        {keywords_stats.failed} failed) in {keywords_stats.elapsed_s / 60:.1f} min —
        **${keywords_stats.est_cost_usd:.2f}** actual token cost.
        Failed rows keep `keywords = NULL` and are picked up by the next run.
        Re-run Stage 7 to get them into the app's search index.
        """
        + ("\n\n⚠️ Errors (first 10):\n" + "\n".join(keywords_stats.errors[:10])
           if keywords_stats.errors else "")
    )
    return


@app.cell(hide_code=True)
def _(con, mo, store):
    _sample = con.execute(
        "SELECT coalesce(display_name, description) AS food, keywords FROM foods "
        "WHERE keywords IS NOT NULL ORDER BY random() LIMIT 15"
    ).pl()
    mo.vstack([
        mo.md(f"**{store.count_enrichment_candidates(con, store.KEYWORDS_PENDING):,}** "
              "rows still have no keywords. A random sample of the ones that do:"),
        mo.ui.table(_sample, selection=None),
    ])
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Model / prompt comparison (read-only)

    Sample random rows and run them through several
    **model : reasoning** configs side by side — one per line, e.g.
    `openai/gpt-4o-mini:high`. The reasoning field is optional and takes an
    effort level (`low`/`medium`/`high`), a token budget (e.g. `512`), or `off`;
    omit it to disable reasoning. The prompt (`STATIC_INSTRUCTIONS`) is shared
    across all configs. Nothing is written to DuckDB; this only shows raw model
    outputs so you can eyeball naming quality.
    """)
    return


@app.cell
def _(con, store):
    compare_pool = store.select_enrichment_candidates(con)  # all candidates, sampled below
    return (compare_pool,)


@app.cell
def _(compare_pool, config, enrich, mo):
    cmp_models = mo.ui.text_area(
        value=config.MODEL,
        label="Configs (one per line, as model[:reasoning])",
        full_width=True,
        rows=3,
    )
    cmp_n = mo.ui.slider(1, min(50, len(compare_pool)), value=10, label="rows to sample", show_value=True)
    cmp_seed = mo.ui.number(start=0, stop=10_000, value=0, label="sample seed")
    cmp_prompt = mo.ui.text_area(
        value=enrich.STATIC_INSTRUCTIONS,
        label="STATIC_INSTRUCTIONS (shared prompt)",
        full_width=True,
        rows=10,
    )
    cmp_button = mo.ui.run_button(label="🔬 Run comparison")
    mo.vstack([
        mo.hstack([cmp_n, cmp_seed], justify="start"),
        cmp_models,
        cmp_prompt,
        cmp_button,
    ])
    return cmp_button, cmp_models, cmp_n, cmp_prompt, cmp_seed


@app.cell(hide_code=True)
async def _(
    asyncio,
    cmp_button,
    cmp_models,
    cmp_n,
    cmp_prompt,
    cmp_seed,
    compare_pool,
    con,
    enrich,
    mo,
):
    mo.stop(not cmp_button.value, mo.md("_Set parameters above and click **Run comparison**._"))

    def _reasoning(tok):  # OpenRouter reasoning: effort level, token budget, or off
        t = tok.strip().lower()
        if t in ("off", "none", "false", "no"):
            return {"enabled": False}
        if t in ("low", "medium", "high"):
            return {"effort": t}
        if t.isdigit():
            return {"max_tokens": int(t)}
        return None  # unrecognized -> treat as not a reasoning field

    def _parse(line):
        # Accepts model | model:reasoning. Model names contain ':' (e.g.
        # tencent/hy3:free), so only peel a trailing reasoning token.
        model, _, tail = line.rpartition(":")
        if model and _reasoning(tail):
            return line, model.strip(), _reasoning(tail)
        return line, line, None

    _specs = [_parse(m.strip()) for m in cmp_models.value.splitlines() if m.strip()]
    mo.stop(not _specs, mo.md("_Enter at least one `model[:reasoning]`._"))
    _rows = compare_pool.sample(n=cmp_n.value, seed=cmp_seed.value).to_dicts()

    async def _one_row(enr, row):
        # the Enricher's semaphore + pacer bound this; without gather the rows
        # would go out strictly serially
        try:
            _it = await enr._fetch(row)
        except Exception as exc:
            return row["fdc_id"], f"⚠️ {type(exc).__name__}: {exc}"
        return row["fdc_id"], (
            f"{_it.display_name}  ·  prep={_it.prep_type or '—'}"
            f"  ·  conf={_it.confidence:.2f}  ·  vf={_it.variable_fat}"
        )

    async def _run_model(model, reasoning):
        _enr = enrich.Enricher(con, model=model, instructions=cmp_prompt.value, reasoning=reasoning)
        return dict(await asyncio.gather(*(_one_row(_enr, _r) for _r in _rows)))

    with mo.status.spinner(title=f"Running {len(_specs)} config(s) × {len(_rows)} rows…"):
        _results = {label: await _run_model(model, reasoning) for label, model, reasoning in _specs}

    _table = [
        {
            "fdc_id": _r["fdc_id"],
            "description": _r["description"],
            **{label: _results[label].get(_r["fdc_id"], "") for label, *_ in _specs},
        }
        for _r in _rows
    ]
    mo.ui.table(_table, selection=None, label=f"seed={cmp_seed.value}")
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 6 — Human review queue

    One row at a time, always the lowest-confidence `needs_review` row
    left. Edit, then **Accept** (`alt+a` — locks it as human-verified, no
    automated pass will ever overwrite it) or **Reject** (`alt+x`). Either
    way the row leaves the queue and the next one loads.
    """)
    return


@app.cell
def _(mo):
    get_review_version, set_review_version = mo.state(0)
    return get_review_version, set_review_version


@app.cell(hide_code=True)
def _(con, get_review_version, store):
    get_review_version()  # re-query after every accept/reject -> the queue head advances
    review_df = store.review_queue(con)
    return (review_df,)


@app.cell(hide_code=True)
def _(config, mo, review_df):
    _row = review_df.to_dicts()[0] if len(review_df) else None
    selected_fdc_id = _row["fdc_id"] if _row else None

    edit_display_name = mo.ui.text(
        value=(_row.get("display_name") or "") if _row else "",
        label="display_name",
        full_width=True,
    )
    edit_emoji = mo.ui.text(
        value=(_row.get("emoji") or "") if _row else "",
        label="emoji",
    )
    edit_prep_type = mo.ui.dropdown(
        options=list(config.PREP_TYPES),
        value=(_row.get("prep_type") if _row and _row.get("prep_type") in config.PREP_TYPES else None),
        label="prep_type (empty = null)",
    )
    edit_variable_fat = mo.ui.switch(
        value=bool(_row.get("variable_fat")) if _row else False,
        label="variable_fat",
    )
    accept_button = mo.ui.run_button(
        label="✅ Accept (verify + lock) · alt+a", kind="success", keyboard_shortcut="Alt-a",
    )
    reject_button = mo.ui.run_button(
        label="❌ Reject · alt+x", kind="danger", keyboard_shortcut="Alt-x",
    )

    _context = (
        mo.md(
            f"**{len(review_df):,} left** · **fdc_id {_row['fdc_id']}** · {_row['data_type']} · "
            f"{_row['food_category'] or '—'}\n\n"
            f"description: `{_row['description']}`\n\n"
            f"fat %: {_row['fat_percentage']} · brand_flagged: {_row['brand_flagged']} · "
            f"confidence: {_row['confidence']}"
        )
        if _row
        else mo.md("🎉 _Review queue empty._")
    )
    mo.vstack([
        _context,
        edit_display_name,
        mo.hstack([edit_emoji, edit_prep_type, edit_variable_fat], justify="start"),
        mo.hstack([accept_button, reject_button], justify="start"),
    ])
    return (
        accept_button,
        edit_display_name,
        edit_emoji,
        edit_prep_type,
        edit_variable_fat,
        reject_button,
        selected_fdc_id,
    )


@app.cell(hide_code=True)
def _(
    accept_button,
    con,
    edit_display_name,
    edit_emoji,
    edit_prep_type,
    edit_variable_fat,
    mo,
    reject_button,
    selected_fdc_id,
    set_review_version,
    store,
):
    mo.stop(not (accept_button.value or reject_button.value))
    mo.stop(selected_fdc_id is None, mo.md("_No row selected._"))
    _accept = bool(accept_button.value)
    _ok = store.apply_human_review(
        con,
        selected_fdc_id,
        display_name=edit_display_name.value or None,
        emoji=edit_emoji.value or None,
        prep_type=edit_prep_type.value,
        variable_fat=edit_variable_fat.value,
        accept=_accept,
    )
    set_review_version(lambda v: v + 1)
    mo.md(
        f"{'✅ Verified' if _accept else '❌ Rejected'} fdc_id {selected_fdc_id}."
        if _ok
        else f"⚠️ fdc_id {selected_fdc_id} not found."
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 6b — Merge duplicate foods

    Groups foods that are the same item into `merged_foods` and points each
    `foods.merged_food_id` at its group, so preparations and fat levels hang
    off one entry instead of showing up as separate search results.

    Two foods are the same item when the same base ingredients drive their
    macros, which shows up as the same **protein:carb:fat ratio**. A ratio is
    invariant to water (raw and cooked land on the same point) and to seasoning
    (salt and pepper carry no macros), but not to a macro-bearing addition — so
    an omelette's oil moves it off the egg point and it stays separate. Foods
    sold at a stated fat level (`80% lean`, `2% milkfat`) are the deliberate
    exception: they merge across the fat axis and the group is marked
    `variable_fat`.

    Deterministic, no LLM, and idempotent — re-run it after tuning
    `config.MERGE_DISTANCE` or `config.MERGE_STOPWORDS`, which are the two
    knobs. Runs in under a second on the full corpus.
    """)
    return


@app.cell
def _(mo):
    merge_button = mo.ui.run_button(label="🔗 Merge duplicate foods")
    merge_button
    return (merge_button,)


@app.cell
def _(con, merge, merge_button, mo):
    mo.stop(not merge_button.value, mo.md("_Click to rebuild the merge groups from the current pipeline state._"))
    _c = merge.run(con)
    _kept = _c["merged_foods"] / _c["foods"] if _c["foods"] else 1.0
    mo.md(
        f"**{_c['foods']:,} foods → {_c['merged_foods']:,} merged items** "
        f"({1 - _kept:.0%} fewer)\n\n"
        f"- {_c['groups']:,} groups hold more than one food\n"
        f"- {_c['variable_fat']:,} span fat levels (`variable_fat`)\n"
        f"- largest group: {_c['largest_group']:,} foods\n"
        + ("\n⚠️ A group this large means the blocking key regressed — check "
           "`config.MERGE_STOPWORDS` for a word that should not be there."
           if _c["largest_group"] > 60 else "")
    )
    return


@app.cell(hide_code=True)
def _(con, merge_button, mo, store):
    # Read-only browser over whatever is in merged_foods, so it works on a fresh
    # kernel without re-running the stage; naming merge_button re-queries it once
    # the stage does run. Groups that look wrong here are fixed in
    # config.MERGE_DISTANCE (too wide/narrow) or MERGE_STOPWORDS (bad key).
    merge_button
    merged_groups = store.merge_groups(con, min_size=2)
    merge_table = mo.ui.table(
        merged_groups,
        selection="single",
        page_size=10,
        label=(
            f"**{len(merged_groups):,} merged items** built from more than one food — "
            "select one to see what it merged from."
            if len(merged_groups)
            else "_No multi-food groups yet — run the stage above._"
        ),
    )
    merge_table
    return (merge_table,)


@app.cell(hide_code=True)
def _(con, merge_table, mo, store):
    _sel = merge_table.value
    mo.stop(not len(_sel), mo.md("_Select a merged item above to see the foods it merged from._"))
    _g = _sel.to_dicts()[0]
    _members = store.merge_members(con, _g["merged_food_id"])
    mo.vstack([
        mo.md(
            f"### {_g['emoji'] or ''} {_g['display_name']}\n\n"
            f"`merged_food_id {_g['merged_food_id']}` · **{_g['n_foods']} foods** · "
            f"{_g['food_category'] or '—'} · group ratio p/c/f "
            f"{_g['p']} / {_g['c']} / {_g['f']}"
            + (" · **variable_fat** (merged across fat levels)" if _g["variable_fat"] else "")
        ),
        mo.ui.table(_members, selection=None, page_size=25),
    ])
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 7 — Build the app catalog and export SQLite

    Re-shapes the pipeline tables into the schema the mobile app queries
    (`app_*` here), then writes `../database/foods.sqlite` — the read-only
    catalog the app bundles, with its FTS5 search indexes already built.

    **Run Stage 6b first.** The catalog carries the merge groups, and
    search collapses to one row per group; without them every food
    exports as its own singleton and the app shows four eggs again.

    Derived and idempotent: safe to re-run after any enrichment or
    review pass, and it never writes to the pipeline tables.
    """)
    return


@app.cell
def _(mo):
    export_button = mo.ui.run_button(label="📦 Build app catalog + export SQLite")
    export_button
    return (export_button,)


@app.cell
def _(appdb, con, config, export_button, mo):
    mo.stop(not export_button.value, mo.md("_Click to rebuild the app catalog from the current pipeline state._"))
    _counts = appdb.run(con, config.SQLITE_PATH)
    _mb = _counts.pop("_bytes") / 1e6
    _missing = con.execute(
        "SELECT count(*) FROM app_foods WHERE emoji IS NULL"
    ).fetchone()[0]
    mo.md(
        f"Wrote `{config.SQLITE_PATH}` — **{_mb:.1f} MB**\n\n"
        + "\n".join(f"- `{_t}`: {_n:,} rows" for _t, _n in _counts.items())
        + (f"\n\n⚠️ {_missing:,} foods still have no emoji — re-run Stage 5."
           if _missing else "")
        + ("\n\n⚠️ Every food exported as its own merged item — Stage 6b has "
           "not run against this database, so the catalog collapses nothing."
           if _counts["merged_foods"] == _counts["foods"] else "")
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 7b — Create the app's writable log database

    Runs `appdb.log_ddl()` against `data/log.sqlite` — the database the app
    writes the user's log, custom foods and recipes into, ATTACH-ed beside the
    read-only catalog. The app creates its own copy on first launch; this one is
    for development, and for checking that the two files actually pair up.

    Idempotent (`CREATE TABLE IF NOT EXISTS` throughout), so re-running it on a
    log with data in it is a no-op.
    """)
    return


@app.cell
def _(mo):
    log_button = mo.ui.run_button(label="🗒️ Create / upgrade the log database")
    log_button
    return (log_button,)


@app.cell
def _(appdb, config, log_button, mo):
    mo.stop(not log_button.value, mo.md("_Click to create `data/log.sqlite` from `appdb.log_ddl()`._"))
    import sqlite3

    _con = sqlite3.connect(config.LOG_PATH)
    _con.execute("PRAGMA foreign_keys = ON")  # per connection, not stored in the file
    _con.executescript(appdb.log_ddl())
    # Baseline for the first migration. Unlike the catalog, which is replaced
    # wholesale, this file holds the only copy of the user's data.
    if not _con.execute("PRAGMA user_version").fetchone()[0]:
        _con.execute("PRAGMA user_version = 1")

    _objects = {
        _label: [_r[0] for _r in _con.execute(
            "SELECT name FROM sqlite_master WHERE type = ? AND name NOT LIKE 'sqlite_%'"
            " ORDER BY name", (_kind,)
        )]
        for _label, _kind in (("tables", "table"), ("indexes", "index"), ("triggers", "trigger"))
    }

    # The log only means anything ATTACH-ed next to the catalog it joins against,
    # so prove that pairing here rather than discovering it on a device. A
    # missing catalog would otherwise be silently *created* empty by ATTACH.
    if config.SQLITE_PATH.exists():
        _con.execute(f"ATTACH DATABASE '{config.SQLITE_PATH}' AS catalog")
        _n = _con.execute(
            "SELECT count(*) FROM catalog.foods f"
            " LEFT JOIN log_entries e ON e.food_id = f.food_id"
        ).fetchone()[0]
        _pairing = f"joins `catalog.foods` — {_n:,} catalog rows reachable"
    else:
        _pairing = f"⚠️ `{config.SQLITE_PATH.name}` not exported yet — run Stage 7 to check the join"
    _con.commit()
    _con.close()

    mo.md(
        f"Wrote `{config.LOG_PATH}` — **{config.LOG_PATH.stat().st_size / 1e3:.0f} KB**, "
        f"schema version 1, {_pairing}.\n\n"
        + "\n".join(f"- {_k} ({len(_v)}): {', '.join(f'`{_n}`' for _n in _v)}"
                    for _k, _v in _objects.items())
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 8 — Upload the catalog to Supabase Storage

    Uploads `../database/foods.sqlite` to a Supabase Storage bucket so the app can
    fetch it. Needs `SUPABASE_URL` and `SUPABASE_SERVICE_KEY` in `.env`
    (`SUPABASE_BUCKET` optional, defaults to `catalog`). Overwrites the
    object in place — same URL every run.
    """)
    return


@app.cell
def _(mo):
    upload_button = mo.ui.run_button(label="☁️ Upload foods.sqlite to Supabase")
    upload_button
    return (upload_button,)


@app.cell
def _(config, mo, upload_button):
    mo.stop(not upload_button.value, mo.md("_Click to upload the exported SQLite catalog._"))
    import os

    import httpx

    _url = os.environ["SUPABASE_URL"].rstrip("/")
    _bucket = os.getenv("SUPABASE_BUCKET", "catalog")
    _object = f"{_bucket}/{config.SQLITE_PATH.name}"
    _body = config.SQLITE_PATH.read_bytes()
    # ponytail: whole file in memory + one request (21 MB, well under Supabase's
    # 50 MB single-shot cap). Switch to the resumable/TUS endpoint if it grows.
    _resp = httpx.post(
        f"{_url}/storage/v1/object/{_object}",
        headers={
            "Authorization": f"Bearer {os.environ['SUPABASE_SERVICE_KEY']}",
            "Content-Type": "application/vnd.sqlite3",
            "x-upsert": "true",
        },
        content=_body,
        timeout=300.0,
    )
    _resp.raise_for_status()
    mo.md(
        f"Uploaded **{len(_body) / 1e6:.1f} MB** to `{_object}`\n\n"
        f"Public URL (if the bucket is public): `{_url}/storage/v1/object/public/{_object}`"
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Pipeline status
    """)
    return


@app.cell
def _(con, get_review_version, mo, store):
    get_review_version()
    mo.vstack([
        mo.md("**Rows by data type / review status** (and recent audit entries):"),
        mo.ui.table(store.status_summary(con), selection=None),
        mo.accordion({"audit_log tail": mo.ui.table(store.audit_tail(con), selection=None)}),
    ])
    return


if __name__ == "__main__":
    app.run()
