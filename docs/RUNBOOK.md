# Part B runbook — one state per run

Execute this to add Shanks-table coverage for the next state. It is written for a
**cold context**: everything you need is here or linked. Read `docs/EXTRACTION.md`
first for the *why*; this file is the *how*. Track progress in `docs/COVERAGE.md`
and resume at the next unfinished state after any context clear.

Start with **Alabama** (top of the ledger). Work **alphabetically; do them all.**

---

## 0. Environment (paths a fresh session needs)

- **Gem repo (this repo):** `~/work/tz_history` — data + tests live here. Branch `main`.
- **App repo:** `/Users/dfl/work/harmonic-explorer` — the Rails app that consumes
  the gem. The Kentucky spike is on worktree
  `/Users/dfl/work/harmonic-explorer-worktrees/feature-shanks-tz-engine`
  (branch `feature/shanks-tz-engine`).
- **Extraction assets** (in the app repo, `research/historical_zones/`):
  - `atlas_ocr/pg###_<st>_timetables.txt` — raw TIME-TABLE OCR for ~23 states already.
  - `<st>_dst_history.md` — the prior per-state DST audit (READ before each state).
  - `OLSON_CROSSCHECK.md`, `parse_timetable.rb` — cross-check notes + the OCR script.
- **Atlas PDF (local, uncommitted, copyrighted — facts only):**
  `~/work/scrapers/Archive.org-Downloader/The_American_atlas__U.S._longitudes_&_latitudes,_time_changes_and_time_zones.pdf`
  Pass as `ENV["ATLAS_PDF"]`.
- **Tools:** `zic` at `/usr/sbin/zic`; `pdftoppm`, `tesseract`, `convert`/`magick` (homebrew).
- **County polygons:** plotly public dataset
  `https://raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json`.
- **Scratch:** use a temp dir; never write atlas crops into the repo.

## Atlas facts (don't rediscover these)

- Alphabetical by state. **Printed page = PDF page − 12.** OCR filenames use the
  **PDF** page (`pg013_al` = PDF 13). TIME TABLES are a state's first page(s);
  CITY LISTINGS follow.
- **6 columns**, monospaced `M/D/YYYY  HH:MM  ZONE`. A numbered table (`AL # 1`)
  **flows down a column and continues at the top of the next** — not within-column wrap.
- TIME TABLES ≈ top 45% of the page; CITY LISTINGS below.
- Render **150 DPI** (`pdftoppm -r 150 -png -gray`). OCR confuses `CDT/CWT/CST` and
  fuses columns — **OCR is a draft, the rendered image is the source of truth.**
- Offsets: `CST −6 · CDT/CWT/CPT −5 · EST −5 · EDT/EWT/EPT −4 · MST −7 · MDT/MWT −6
  · PST −8 · PDT/PWT −7`; `US#n` = federal uniform from that date (defer to IANA after).

## Non-negotiable gotchas

- **Visual-verify every table** (a subagent reads the rendered crop and corrects
  OCR). Blind OCR = a silent 1-hour error, the exact bug we exist to fix.
- **Offset, not abbreviation,** is what matters (Shanks CWT == IANA CDT == −05 DST).
- **Never `JSON.pretty_generate` the whole geojson** — it explodes coordinates
  (see `git log` for the KY near-miss). Keep geometry one compact line per feature;
  edit textually or via `tools/add_feature.rb`.
- App consumers wrap the result: `ActiveSupport::TimeZone.create(tz.identifier, nil, tz)`.

---

## 1. First run only — build `tools/` (then reuse forever)

Implement the dev-only tools specced in `docs/EXTRACTION.md` §6:
`tools/render_state.rb`, `tools/ocr_tables.rb`, `tools/triage.rb`,
`tools/zic_from_json.rb`, `tools/add_feature.rb`. Also generalize the cross-check
(§5): a `SHANKS ↔ IANA` map + one parameterized test (KY_69↔Louisville seeds it).

**Acceptance for the tools:** running triage on Kentucky reproduces exactly the two
tables we already ship (#69, #71) and nothing else. If it doesn't, the tool is wrong.

Commit tools separately: `chore: Part B extraction tooling`.

---

## 2. Per-state procedure (the loop)

Let `S` = next `pending` state in `docs/COVERAGE.md`.

1. **Read the audit.** `research/historical_zones/<st>_dst_history.md` and the
   relevant `OLSON_CROSSCHECK.md` section — it usually already names the residual
   (e.g. AL: the real 1941 summer-DST episode).
2. **Render TIME TABLES.** Use the PDF page from the ledger (or find it: printed
   page from the atlas, +12). `tools/render_state.rb $ATLAS_PDF <pdf_page>`.
3. **Triage** (`tools/triage.rb`): compile the state's tables and flag any table +
   year-range where its offset beats **both** the shipped flat override and IANA.
   - **No hits → state is done.** Mark ledger `flat/IANA sufficient`, commit, next state.
   - Hits → those tables (only) proceed.
4. **Transcribe (visual-verify).** For each flagged table, a subagent reads the
   rendered crop and emits the exact transition list JSON. Reconcile column
   flow-down-then-wrap and CDT/CWT confusion against the image.
5. **Author + compile.** `tools/zic_from_json.rb` → `data/shanks/<ST>_<n>.zic`
   (with a provenance header: printed page, table #, IANA-checked or visual-only).
   `rake shanks:build`.
6. **Verify offsets.**
   - IANA twin exists → add to the cross-check map; the parameterized test must pass.
   - No twin → add hand assertions for the known DST seasons in `test/`.
7. **Map counties → table.** OCR the CITY LISTINGS (below the tables), resolve
   `city → county# → table#`, **majority-vote per county**. `warn` (don't guess)
   genuinely split counties; log them.
8. **Add features.** `tools/add_feature.rb` for each qualifying county: FIPS
   polygon + `shanks: "<ST>_<n>"` + `from_date`/`until_date` window (start where it
   diverges from the shipped answer; end at the state's uniform-time adoption or
   war-time start, after which IANA is correct).
9. **Regression.** `rake test` green (new assertions + all existing unchanged);
   `bundle exec rubocop` clean.
10. **Ledger + commit.** Update the `S` row in `docs/COVERAGE.md`. Commit:
    `feature: Shanks coverage for <State> (tables #…)` — include what qualified and
    what stayed flat. Then next state.

## Definition of done (per state)

Qualifying tables transcribed/verified/compiled; cross-check or hand assertions
pass; county features added (compact geometry); split/fallback counties logged;
`rake test` + rubocop green; ledger row updated; `.zic` provenance headers complete.

## Committing

Gem repo `main`, prefixes `feature:`/`chore:`/`research:`, present tense. End
messages with:

```
Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
Claude-Session: <the current session url>
```

Don't push unless asked. When a state also needs the *app* rewired to the gem,
that's a separate one-time change in the app repo (see `docs/EXTRACTION.md` intro),
not part of per-state runs.
