# Part B — Shanks table extraction pipeline

How to grow `tz_history` from the Kentucky spike to national pre-1970 coverage by
transcribing more Shanks *American Atlas* TIME TABLES into synthetic zones.

This is the open-ended, human-in-the-loop half of the project. The engine (Part A)
is done; Part B is disciplined data entry with automated safety nets. Do it
**state by state**, each state a self-contained, verifiable unit.

---

## 1. What actually needs doing (scope)

We do **not** transcribe all ~3000 counties, or even every Shanks table. Two kinds
of correction already cover most of the country:

- **Flat overrides** (`Etc/GMT+N`) — carried over from harmonic-explorer for
  counties that kept a single standard offset year-round (no DST) pre-1970. These
  are already correct; leave them alone.
- **IANA** — every county not in the dataset defers to its modern IANA zone,
  correct for post-1970 and for pre-1970 standard time.

A Shanks transition-list zone is only needed for the residual case the flat model
**cannot** represent: a county that observed a **seasonal DST alternation** pre-1970
that IANA does not model. That is exactly the "summer-DST limitation":

- Louisville 1921/1941 (done — handled by IANA guard)
- northern KY / Campbell+Kenton 1920-1926 (done — `Shanks/KY_71`)
- Atlanta 1937-1939; assorted one-off urban local-DST years elsewhere

**A table qualifies for a Shanks upgrade iff** it contains a daylight (`xDT`)
transition, in a year and region where the currently-shipped answer (flat override
or IANA) gives the wrong offset. Everything else stays as-is.

The prior multi-state audit (`research/historical_zones/*_dst_history.md`, 18
states) found most pre-1941 history was year-round standard — so the qualifying set
is **small and specific**, not "20 states of heavy work." Part B is a hunt for
those specific county×era pockets, not a national re-transcription.

---

## 2. Atlas mechanics (learned from the KY spike)

Source PDF (local, not committed — copyrighted; facts only are extracted):
`~/work/scrapers/Archive.org-Downloader/The_American_atlas...pdf`

- **Alphabetical by state.** Printed page = PDF page − 12. TIME TABLES are the
  first page(s) of a state's section; CITY LISTINGS follow.
- **6 columns per page**, monospaced `M/D/YYYY  HH:MM  ZONE` rows. Tables are
  numbered (`KY # 69`); a table **flows down one column and continues at the top of
  the next** — it does not wrap within a column. Account for this when reconstructing.
- TIME TABLES occupy roughly the **top 45%** of the page; CITY LISTINGS below map
  `city → county → table#`.
- Render at **150 DPI** (300 makes tesseract choke): `pdftoppm -f P -l P -r 150 -png -gray`.
- OCR confuses `CDT/CWT/CST`, fuses adjacent columns, and drops rows. **OCR is a
  draft, never the source of truth** — every table gets a visual-verify pass.

Zone-code → offset: `CST −6 / CDT,CWT,CPT −5 / EST −5 / EDT,EWT,EPT −4 /
MST −7 / MDT,MWT −6 / PST −8 / PDT,PWT −7`; `LMT` (pre-1883, irrelevant to births);
`US#n` = federal uniform rules from that date (defer to IANA thereafter).

---

## 3. Per-table pipeline

For each candidate table:

1. **Render + column-crop + OCR** the TIME TABLES page
   (`research/historical_zones/parse_timetable.rb` is the starting point).
2. **Triage** (§4): keep only tables with a pre-uniform daylight transition that
   the shipped answer misses. Discard the rest (they stay flat/IANA).
3. **Visual-verify transcription.** A subagent reads the rendered table crop and
   produces the exact transition list, reconciling OCR noise against the image
   (this is how KY #69/#71 were transcribed). Output a structured list:
   `[{at_local: "1923-03-28 02:00", off: -21600, dst: false, abbr: "CST"}, ...]`.
4. **Author the `.zic`** from that list (§6 tool). Compile with `rake shanks:build`.
5. **Cross-check** (§5): if a matching IANA sub-zone exists, assert offset
   equivalence 1884→uniform-year; otherwise the visual-verify pass is the check.
6. **Map counties → table** (§7) and add geojson feature(s).
7. **Regression**: `rake test` — new gold assertions pass, existing overrides
   unchanged.

Never skip 3 or 5. Blind OCR → a silent 1-hour error, the exact bug we exist to fix.

---

## 4. Data-driven candidate detection (triage tool)

Don't eyeball 70 tables per state. Build `tools/triage.rb`:

- Input: a state's OCR'd tables (even noisy) compiled to throwaway TZif.
- For each table, scan 1918→1966 monthly and flag any month where the table's
  offset **differs from both** (a) the flat override currently shipped for that
  region and (b) the IANA modern zone. Those deltas are the only reason to upgrade.
- Emit a ranked candidate list: `table# → [year-ranges with a missed DST season]`.

This turns "which tables matter?" into a computed answer and bounds the manual work
to the flagged tables only. Tables with zero deltas are provably already correct.

---

## 5. Cross-check harness (generalize the KY #69 gold test)

`test/zone_test.rb` proves `Shanks/KY_69 == America/Kentucky/Louisville` on offset,
every month 1884-1969. Generalize this:

- Maintain a table `SHANKS ↔ IANA` map of every synthetic zone that has a genuine
  IANA counterpart (Louisville, and any future table that matches an IANA sub-zone).
- One parameterized test asserts offset-equivalence across the overlap span.
- A mismatch is an **OCR/transcription bug to fix**, not new data — this is the
  regression net that makes bulk extraction safe.
- Tables with **no** IANA counterpart (e.g. `KY_71`) carry hand-written assertions
  for their known DST summers instead (already in `tz_history_test.rb`).

---

## 6. Tooling to build (all dev-only, not packaged)

| Tool | Purpose |
|------|---------|
| `tools/render_state.rb` | PDF page → 150dpi PNG + 6 column crops (wraps `pdftoppm`/`convert`). |
| `tools/ocr_tables.rb` | column OCR → rough transitions JSON (from `parse_timetable.rb`). |
| `tools/triage.rb` | §4 — flag tables whose offsets beat the shipped answer. |
| `tools/zic_from_json.rb` | verified transitions JSON → `data/shanks/<ST>_<n>.zic`. |
| `tools/add_feature.rb` | county FIPS + table + window → geojson feature (compact geometry). |

**County polygons**: fetch by FIPS from the plotly public dataset
(`raw.githubusercontent.com/plotly/datasets/master/geojson-counties-fips.json`),
the same source the existing features use. Keep geometry **one line per feature**
(compact) — never `JSON.pretty_generate` the whole file (it explodes coordinates).
Edit the geojson textually or via `tools/add_feature.rb`, which preserves that.

The atlas PDF path is passed via `ENV["ATLAS_PDF"]`; nothing atlas-derived beyond
re-expressed facts is committed.

---

## 7. County → table mapping

From the CITY LISTINGS (lower ~55% of each state page):

- OCR `city  county#  table#` rows; resolve `county# → county name/FIPS`.
- **Majority-vote per county**: a county's table = the table most of its cities use.
- **`warn`, don't guess**, for counties that genuinely straddle a table boundary
  (record them in the state ledger, ship a warn feature, no override).

Only counties whose table qualified in §4 need a feature; the rest defer to the
existing flat override or IANA.

---

## 8. Provenance & legal (per-table discipline)

Time-zone transition dates are **facts** — not copyrightable (*Feist v. Rural*;
cf. *Astrolabe v. Olson*). We re-express them as our own `.zic`/GeoJSON and
cross-check against public-domain IANA. Requirements:

- Ship **no verbatim atlas tables or prose** — only re-expressed transition lists.
- Each `.zic` header records provenance: atlas printed page, table #, and whether it
  was IANA-cross-checked or visual-verified only (see `KY_69.zic`/`KY_71.zic`).
- The atlas PDF stays local and uncommitted.

---

## 9. Prioritization & state ledger

Order by population impact and by "already audited" (fast wins). Track every state
in a ledger (`docs/COVERAGE.md`) with one row per state:

`state | uniform-year | flat-override? | shanks tables | qualifying counties | cross-check | status`

Suggested order:
1. **Pilot**: re-run the pipeline end-to-end on **one already-audited state** with a
   known residual (Ohio/Hamilton–Cincinnati, adjacent to the KY work, or Georgia/
   Atlanta 1937-39) to validate tooling at scale.
2. Remaining audited states that would gain residual DST summers (GA, OH, WI, ...).
3. High-population unaudited states.
4. Long tail (rural, low-impact) — leave on flat/IANA unless a delta shows up.

Log every fallback (majority-vote county, table left flat, warn) so "12 states
done" never reads as "everything covered."

---

## 10. Definition of done (per state)

- Every qualifying table transcribed, visual-verified, compiled.
- Cross-check passes for tables with an IANA counterpart; hand assertions for the rest.
- County features added (compact geometry); majority-vote/warn cases logged.
- `rake test` green; existing overrides unchanged.
- `docs/COVERAGE.md` row updated; `.zic` provenance headers complete.

---

## 11. How the work is structured

There is no separate "tooling phase." **Each state is one self-contained run**
(see `docs/RUNBOOK.md`). The *first* run also builds the reusable `tools/` (§6);
every later run just reuses them. Progress is tracked in `docs/COVERAGE.md` so a
fresh session (post context-clear) resumes at the next unfinished state.

Order: **alphabetical over the 48 CONUS states** (exhaustive — we do them all).
A state with no qualifying table (§4) is still "done": it's confirmed flat/IANA-
sufficient and closed out in the ledger. Kentucky is already complete.
