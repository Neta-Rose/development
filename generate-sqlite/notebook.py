import marimo

__generated_with = "0.23.15"
app = marimo.App(width="medium")


@app.cell
def _():
    import marimo as mo
    import duckdb

    return (mo,)


@app.cell
def _(con, mo):
    _df = mo.sql(f"""
    SELECT * FROM "merged_foods" LIMIT 100
    """, engine=con)
    return


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

    Run order: **Ingest → Cleanup → Brand flags → Canonicalize → Cluster →
    Sample enrich → Full enrich → Review → Export**. Every stage is resumable
    and idempotent; human-verified items are never overwritten by re-runs.
    """)
    return


@app.cell(hide_code=True)
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

    from src import (
        abbrev, appdb, brand_detect, canon, cluster, config, enrich, ingest, store,
    )

    return (
        abbrev,
        appdb,
        asyncio,
        brand_detect,
        canon,
        cluster,
        config,
        enrich,
        ingest,
        store,
    )


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
        f"inserted {ingest_counts['inserted']:,}, updated {ingest_counts['updated']:,}.\n\n"
        + " · ".join(f"{t} {n:,}" for t, n in child_counts.items())
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
    ## Stage 3b-1 — Canonicalize (LLM)

    Reads every food's description and writes down what it **is**: a
    `base_name` (the identity, with every cooking, grade and trim word
    removed), a `food_kind` (`ingredient` or `dish`), and the `prep_label` this
    particular record was prepared at. Stage 3b then groups on `base_name` and
    `food_kind` alone.

    This is the stage that replaced two hand-tuned thresholds. Word overlap
    could not tell an ingredient word from a handling word — "granola bars,
    hard, plain" and "granola bars, hard, almond" scored 0.75 and merged — and
    macros are not an identity signal at all, so 6,586 token-similar pairs were
    rejected on the ratio, 698 of them the same food in two USDA databases.
    Both are semantic judgments, so they are asked rather than approximated.

    Foods go out ~40 per request, ordered so that a food's several USDA records
    are **adjacent**. That is the consistency mechanism, not a cost trick: the
    model sees "Rice, white, raw" beside "Rice, white, steamed" and writes one
    base name for both. Resumable — a food with a `base_name` is never re-sent,
    and a batch that fails validation twice is left alone rather than written
    half-way. Cost is a fraction of Stage 4's (~$0.12 for the full corpus).

    **Run the sample first** (it uses the same model box as Stage 4, below) and
    read the answers in the table underneath before committing to the full
    corpus. To re-do the pass with a changed prompt:
    `UPDATE foods SET base_name = NULL`.
    """)
    return


@app.cell
def _(mo):
    canon_sample_button = mo.ui.run_button(label="🧪 Canonicalize a sample (200 foods)")
    canon_button = mo.ui.run_button(label="🏷️ Canonicalize all remaining foods")
    mo.vstack([canon_sample_button, canon_button])
    return canon_button, canon_sample_button


@app.cell
async def _(
    canon,
    canon_button,
    canon_sample_button,
    con,
    concurrency_slider,
    config,
    enrich_model,
    enrich_reasoning,
    mo,
):
    mo.stop(
        not (canon_sample_button.value or canon_button.value),
        mo.md("_Click to read an identity off every un-canonicalized food._"),
    )
    _limit = config.SAMPLE_SIZE if canon_sample_button.value else None
    _total = min(canon.count_candidates(con), _limit or 1 << 30)
    _seen = [0]  # d is cumulative and throttled; the bar wants a delta

    def _canon_progress(d, t, stats, elapsed):
        _step, _seen[0] = d - _seen[0], d
        _bar.update(
            increment=_step,
            subtitle=f"${stats.est_cost_usd:.4f} · {stats.failed} foods failed",
        )

    with mo.status.progress_bar(total=_total, title="Canonicalizing") as _bar:
        canon_stats = await canon.run(
            con, limit=_limit, model=enrich_model, reasoning=enrich_reasoning,
            concurrency=concurrency_slider.value, progress_cb=_canon_progress,
        )
    mo.md(
        f"**{canon_stats.succeeded:,}/{canon_stats.requested:,} foods canonicalized** "
        f"({canon_stats.failed:,} failed) in {canon_stats.elapsed_s:.0f}s for "
        f"**${canon_stats.est_cost_usd:.4f}**.\n\n"
        f"{canon.count_candidates(con):,} foods still have no identity. "
        f"Prompt cache: {canon_stats.cache_hit_rate:.0%}.\n"
        + ("\n⚠️ Errors:\n" + "\n".join(canon_stats.errors[:10])
           if canon_stats.errors else "")
    )
    return (canon_stats,)


@app.cell
def _(canon_stats, con, mo):
    # Read the answers before spending on the rest of the corpus. Grouped by
    # base_key, because that is what clustering will actually do with them —
    # a base name that reads fine in isolation can still be one that collapses
    # two foods, and only the grouping shows it. Naming canon_stats is what
    # makes this re-run after a pass rather than on a cold kernel.
    canon_stats
    mo.ui.table(
        con.execute(
            """
            SELECT base_key, any_value(food_kind) AS kind, count(*) AS n_foods,
                   string_agg(DISTINCT coalesce(prep_label, '—'), ', ') AS preps,
                   string_agg(description, ' | ' ORDER BY fdc_id) AS members
            FROM foods WHERE base_name IS NOT NULL
            GROUP BY base_key ORDER BY n_foods DESC, base_key
            LIMIT 500
            """
        ).pl(),
        label="Identities, biggest first — check that nothing here is two foods",
    )
    return


@app.cell
def _(con, mo):
    _df = mo.sql(
        f"""
        SELECT * FROM "foods" where base_key is not null LIMIT 1000
        """,
        engine=con
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 3b — Cluster into items and preparations

    Groups the corpus into the two-level structure the app shows: an **item**
    (one row in the search list) holding one or more **preparations** (the
    variant selector). Fills `merged_foods`, `merged_preps`, and points every
    `foods.merged_food_id` / `foods.prep_id` at them.

    An item is every food sharing a `base_key` and a `food_kind` — identity is
    a **key**, not a pairwise test, which is what makes it transitive for free.
    `food_kind` is in the key because a dish is never a preparation of an
    ingredient it is made of: fried rice cannot join white rice, whatever the
    words or the numbers say.

    Where one identity's own records disagree about its kind — the model
    contradicting itself across two requests, never a real distinction in the
    121 cases measured — the **majority** decides and ties break to
    `ingredient`. It declines on identities written more than one way, since
    those are the ones the token sort may have collided; that is the safety
    gate, and it is what the count below is now reporting.

    Within an item, preparations start from the labels Stage 3b-1 read off the
    descriptions and are then **merged** where the macros agree — grilled,
    boiled and baked land on one profile and become one preparation called
    "cooked". Labels first is what stops the same food recorded in two USDA
    databases with different numbers from becoming two preparations. Foods sold
    at a stated fat level (`80% lean`, `2% milkfat`) key alike and the item is
    marked `variable_fat`.

    Deterministic, no LLM, idempotent, and **non-destructive** — re-running it
    keeps every name Stage 4 produced and only re-queues the items whose
    membership actually moved. ~2 s on the full corpus.
    """)
    return


@app.cell
def _(mo):
    cluster_button = mo.ui.run_button(label="🔗 Cluster into items")
    cluster_button
    return (cluster_button,)


@app.cell
def _(cluster, cluster_button, con, mo):
    mo.stop(not cluster_button.value, mo.md("_Click to rebuild the item/preparation grouping from the current pipeline state._"))
    _c = cluster.run(con)
    _kept = _c["items"] / _c["foods"] if _c["foods"] else 1.0
    mo.md(
        f"**{_c['foods']:,} foods → {_c['items']:,} items / {_c['preps']:,} preparations** "
        f"({1 - _kept:.0%} fewer rows in search)\n\n"
        f"- {_c['multi_food_items']:,} items hold more than one food\n"
        f"- {_c['multi_prep_items']:,} items have more than one preparation\n"
        f"- {_c['dishes']:,} foods are dishes rather than ingredients\n"
        f"- {_c['variable_fat']:,} span fat levels (`variable_fat`)\n"
        f"- largest item: {_c['largest_item']:,} foods\n\n"
        f"Corpus quality — watch these move:\n\n"
        f"- {len(_c['kind_splits']):,} identities kept an ingredient/dish split "
        f"the vote declined to resolve\n"
        f"- {len(_c['spelling_splits']):,} identities are written more than one way\n"
        f"- {len(_c['leaked_cooking_words']):,} identities leaked a cooking word "
        f"and cost a duplicate item\n"
        f"- {_c['unstated_preps']:,} preparations hold a food that stated no "
        f"preparation of its own\n\n"
        f"Enrichment state: {_c['created']:,} new, {_c['requeued']:,} re-queued "
        f"(membership changed), {_c['dissolved']:,} dissolved.\n"
        + (f"\n⚠️ {_c['uncanonicalized']:,} foods have no `base_name` and are "
           "singleton items — run Stage 3b-1.\n" if _c["uncanonicalized"] else "")
        + (f"\n⚠️ {len(_c['kind_splits'])} identities disagree on `food_kind` AND "
           "are written more than one way, so the vote declined and each is two "
           f"items instead of one: `{'`, `'.join(_c['kind_splits'][:8])}`. Fixing "
           "the spelling is what resolves them — re-canonicalize just those foods "
           "(`UPDATE foods SET base_name = NULL WHERE base_key IN (…)`).\n"
           if _c["kind_splits"] else "")
        + ("\n⚠️ An item this large is two foods sharing a base name — find it "
           "in the Stage 3b-1 table above and fix the prompt, not a threshold."
           if _c["largest_item"] > 60 else "")
    )
    return


@app.cell(hide_code=True)
def _(cluster_button, con, mo, store):
    # Read-only browser over whatever is in merged_foods, so it works on a fresh
    # kernel without re-running the stage; naming cluster_button re-queries it
    # once the stage does run. Items that look wrong here are fixed in
    # the canon.py prompt: a base name that is two foods, or one food written
    # two ways. There is no threshold to turn here any more.
    cluster_button
    cluster_list = store.cluster_items(con, min_size=2)
    cluster_table = mo.ui.table(
        cluster_list,
        selection="single",
        page_size=10,
        label=(
            f"**{len(cluster_list):,} items** built from more than one food — "
            "select one to see its preparations and members."
            if len(cluster_list)
            else "_No multi-food items yet — run the stage above._"
        ),
    )
    cluster_table
    return (cluster_table,)


@app.cell(hide_code=True)
def _(cluster_table, con, mo, store):
    _sel = cluster_table.value
    mo.stop(not len(_sel), mo.md("_Select an item above to see the foods it was built from._"))
    _g = _sel.to_dicts()[0]
    _members = store.cluster_members(con, _g["merged_food_id"])
    mo.vstack([
        mo.md(
            f"### {_g['emoji'] or ''} {_g['display_name'] or '_(not yet named)_'}\n\n"
            f"`merged_food_id {_g['merged_food_id']}` · **{_g['n_foods']} foods** in "
            f"**{_g['n_preps']} preparations** · {_g['food_category'] or '—'}"
            + (f" · preparations: {_g['preps']}" if _g["preps"] else "")
            + (" · **variable_fat** (spans fat levels)" if _g["variable_fat"] else "")
        ),
        mo.ui.table(_members, selection=None, page_size=25),
    ])
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 4 — LLM enrichment (OpenRouter)

    One request per **item** from Stage 3b, asking only how to *present* it:
    display_name, emoji, keywords, commonness. Everything factual was settled
    upstream — Stage 3b-1 read each member's identity and preparation off its
    description, and Stage 3b grouped on that — so this pass no longer types
    preparations and no longer decides anything clustering depends on.

    `display_name` is the item's `base_name`, written the way a label would
    write it. It must keep every qualifier the base carries (that is what
    separates this item from the one beside it) and must never add a
    preparation word (the preparation is joined back at display time). Both are
    checked deterministically in `store.cross_check`, and a name that fails
    goes to review whatever confidence the model claimed.

    The model box below is shared with Stage 3b-1.

    **Always run the sample first.** It processes ~200 items, measures token
    usage and latency, and extrapolates cost for the full corpus before you
    commit to it. Both runs are resumable: completed items are skipped,
    human-verified items are never re-enriched.
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
    ## Model / prompt comparison (read-only)

    Sample random **items** and run them through several
    **model : reasoning** configs side by side — one per line, e.g.
    `openai/gpt-4o-mini:high`. The reasoning field is optional and takes an
    effort level (`low`/`medium`/`high`), a token budget (e.g. `512`), or `off`;
    omit it to disable reasoning. The prompt (`STATIC_INSTRUCTIONS`) is shared
    across all configs. Nothing is written to DuckDB; this only shows raw model
    outputs so you can eyeball naming and preparation-labelling quality.

    Run Stage 3b first — this samples from the same queue Stage 4 uses.
    """)
    return


@app.cell
def _(con, store):
    compare_pool = store.select_enrichment_candidates(con)  # all pending items, sampled below
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

    async def _one_item(enr, row):
        # the Enricher's semaphore + pacer bound this; without gather the items
        # would go out strictly serially
        try:
            _it = await enr._fetch(row)
        except Exception as exc:
            return row["merged_food_id"], f"⚠️ {type(exc).__name__}: {exc}"
        _preps = " / ".join(
            p.prep_type or "—" for p in sorted(_it.preps, key=lambda p: p.i)
        )
        return row["merged_food_id"], (
            f"{_it.emoji} {_it.display_name}  ·  [{_preps}]"
            f"  ·  conf={_it.confidence:.2f}  ·  common={_it.commonness:.2f}"
            f"\n{', '.join(_it.keywords)}"
        )

    async def _run_model(model, reasoning):
        _enr = enrich.Enricher(con, model=model, instructions=cmp_prompt.value, reasoning=reasoning)
        return dict(await asyncio.gather(*(_one_item(_enr, _r) for _r in _rows)))

    with mo.status.spinner(title=f"Running {len(_specs)} config(s) × {len(_rows)} items…"):
        _results = {label: await _run_model(model, reasoning) for label, model, reasoning in _specs}

    _table = [
        {
            "item": _r["merged_food_id"],
            # the item has no name yet — show what the model was actually given
            "members": " | ".join(
                _d for _p in _r["preps"] for _d in _p["descs"]
            )[:160],
            **{label: _results[label].get(_r["merged_food_id"], "") for label, *_ in _specs},
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
def _(mo, review_df):
    _row = review_df.to_dicts()[0] if len(review_df) else None
    selected_item_id = _row["merged_food_id"] if _row else None

    edit_display_name = mo.ui.text(
        value=(_row.get("display_name") or "") if _row else "",
        label="display_name",
        full_width=True,
    )
    edit_emoji = mo.ui.text(
        value=(_row.get("emoji") or "") if _row else "",
        label="emoji",
    )
    edit_keywords = mo.ui.text(
        value=(_row.get("keywords") or "") if _row else "",
        label="keywords ('; '-joined)",
        full_width=True,
    )
    accept_button = mo.ui.run_button(
        label="✅ Accept (verify + lock) · alt+a", kind="success", keyboard_shortcut="Alt-a",
    )
    reject_button = mo.ui.run_button(
        label="❌ Reject · alt+x", kind="danger", keyboard_shortcut="Alt-x",
    )

    # prep_type is not editable here: it is derived from the canonicalized
    # labels now, so an edit would be overwritten by the next cluster.run().
    # Fix it upstream, in foods.prep_label.
    _context = (
        mo.md(
            f"**{len(review_df):,} left** · **item {_row['merged_food_id']}** · "
            f"{_row['food_category'] or '—'}\n\n"
            f"description: `{_row['description']}`\n\n"
            f"{_row['n_foods']} foods in {_row['n_preps']} preparations"
            + (f" ({_row['preps']})" if _row["preps"] else "")
            + f" · brand_flagged: {_row['brand_flagged']}"
            + f" · variable_fat: {_row['variable_fat']}"
            + f" · confidence: {_row['confidence']}"
        )
        if _row
        else mo.md("🎉 _Review queue empty._")
    )
    mo.vstack([
        _context,
        edit_display_name,
        edit_keywords,
        mo.hstack([edit_emoji], justify="start"),
        mo.hstack([accept_button, reject_button], justify="start"),
    ])
    return (
        accept_button,
        edit_display_name,
        edit_emoji,
        edit_keywords,
        reject_button,
        selected_item_id,
    )


@app.cell
def _(con, mo):
    _df = mo.sql(
        f"""
        SELECT * FROM "foods" LIMIT 100
        """,
        engine=con
    )
    return


@app.cell
def _(con, mo):
    _df = mo.sql(
        f"""
        SELECT * FROM "merged_foods" LIMIT 100
        """,
        engine=con
    )
    return


@app.cell(hide_code=True)
def _(
    accept_button,
    con,
    edit_display_name,
    edit_emoji,
    edit_keywords,
    mo,
    reject_button,
    selected_item_id,
    set_review_version,
    store,
):
    mo.stop(not (accept_button.value or reject_button.value))
    mo.stop(selected_item_id is None, mo.md("_No item selected._"))
    _accept = bool(accept_button.value)
    _ok = store.apply_human_review(
        con,
        selected_item_id,
        display_name=edit_display_name.value or None,
        emoji=edit_emoji.value or None,
        keywords=edit_keywords.value or None,
        accept=_accept,
    )
    set_review_version(lambda v: v + 1)
    mo.md(
        f"{'✅ Verified' if _accept else '❌ Rejected'} item {selected_item_id}."
        if _ok
        else f"⚠️ item {selected_item_id} not found."
    )
    return


@app.cell(hide_code=True)
def _(mo):
    mo.md(r"""
    ## Stage 7 — Build the app catalog and export SQLite

    Re-shapes the pipeline tables into the schema the mobile app queries
    (`app_*` here), then writes `../database/foods.sqlite` — the read-only
    catalog the app bundles, with its FTS5 search indexes already built.

    **Run Stage 3b first.** The catalog is indexed one row per item, not
    per food; without the grouping every food exports as its own singleton
    and the app shows four eggs again.

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
        "SELECT count(*) FROM app_merged_foods WHERE display_name IS NULL"
    ).fetchone()[0]
    mo.md(
        f"Wrote `{config.SQLITE_PATH}` — **{_mb:.1f} MB**\n\n"
        + "\n".join(f"- `{_t}`: {_n:,} rows" for _t, _n in _counts.items())
        + (f"\n\n⚠️ {_missing:,} items are still unnamed — re-run Stage 4. They "
           "fall back to their USDA description in search."
           if _missing else "")
        + ("\n\n⚠️ Every food exported as its own item — Stage 3b has "
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
