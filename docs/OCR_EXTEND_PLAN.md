# Execution plan — apply the improved `ocr_tables` to extend/repair shipped states

Status: ready to execute (2026-09). Written to survive a context clear — everything needed to
start cold is here. `ocr_tables.rb` was rewritten this session (commit `1bbf6ae`, branch
`feature/maine`): it now reads, per table, the **base zone** (CST/EST/MST/PST from the row
abbreviations) AND the **DST pattern** (peacetime-DST years, postwar resume year, or NO-DST),
numbered from the `XX # N` header. Validated Maryland 28/28, Idaho 18/18. See
`docs/OCR_TABLES_PLAN.md` for how it works and its limits.

## Environment (run every task from here)

- Worktree: `~/work/tz_history-worktrees/ocr-nearest-city`, branch `feature/maine`.
- `export ATLAS_PDF="/Users/dfl/work/scrapers/Archive.org-Downloader/The_American_atlas__U.S._longitudes_&_latitudes,_time_changes_and_time_zones.pdf"`
- `export SCRATCH="<a scratchpad dir>"` (never render into the repo — atlas is copyrighted).
- **Render + classify a state's TIME TABLES** (~50s/page, on-device Vision OCR):
  ```
  ruby tools/render_state.rb <PDF_PG> --cols=1 --top=0 --bot=0.88 --band-h=2400 --out=$SCRATCH/<st>
  ruby tools/ocr_tables.rb $SCRATCH/<st> --debug
  ```
  `--bot=0.88` (NOT 0.45) or the bottom table of every column clips. `--debug` prints per-column
  counts + a region-floor warning if a table is still being cut off (raise `--bot`).
- TT page numbers (`tools/atlas_pages.tsv`): **GA 104, IL 128, IN 150, ME 229, MA 254**;
  ID 122, MD 239. (Verify by reading the rendered header caption — the ledger has lied before.)

## The two GATES (unchanged — OCR is a draft, never author from it directly)

1. **Visual verify**: the main agent Reads the rendered PNG crop of the target table(s) and
   confirms the pattern by eye before shipping. `magick $SCRATCH/<st>/full.png -crop
   <w>x<h>+<x>+<y> +repage -resize 760x out.png` then Read it.
2. **SHANKS↔IANA cross-check test**: add/extend a regression test in `test/tz_history_test.rb`
   asserting the corrected offset differs from IANA where expected and matches elsewhere.
   Run `rake test` (or `ruby -Itest test/tz_history_test.rb`). Rebuild shanks zics after edits:
   `rake shanks:build`.

Data anchors: overrides live in `data/us_historical_zones.geojson`; per-town transition zones
in `data/shanks/<XX_N>.zic` (referenced by a feature's `"shanks":"XX_N"`); flat overrides are
`Etc/GMT+N` zone features; `warn`/exclusion guards are feature kinds. Tools: `map_counties.rb`
(city→county→table majority + `--split-emit`), `add_feature.rb`, `zic_from_json.rb`,
`analyze_split.rb` (geographic-separability). Read each tool's header comment for exact flags.

## Priorities (corrected after reading DEFERRED.md + COVERAGE.md — do NOT redo Idaho)

**Idaho is DONE.** DEFERRED #5 (the 5 resumer tables ID#1/4/7/10/12 → `ID_1` zic) is FIXED;
the remaining ID items (#6 pre-war local DST, #7 postwar MDT, #8 1919 sliver) are explicitly
minority / low value with **no county majority**, so there is nothing new to ship even with
perfect OCR. Skip Idaho.

### TASK 1 — Georgia N/NE-mountain boundary counties (page 104) — HIGHEST ROI
A bounded **correctness fix to a shipped state**, and the exact thing that was waiting on a GA
time-tables crop. DEFERRED #1 residual: `Union, Fannin, Gilmer, Lumpkin, Dawson, Pickens,
Bartow` may be wrongly kept in the Western-GA **Central** set; the city index's per-town table#
does NOT encode Central-vs-Eastern (t8 appears in both). `ocr_tables` now reads each table's
base zone (CST vs EST rows) directly, which answers it.
Steps:
1. Render+classify GA (pg 104). Note which table numbers are CST-based vs EST-based.
2. Map each of the 7 boundary counties → its dominant table# via `tools/map_counties.rb` over
   the GA city listings (the index already exists in `research/index/GA/`).
3. For each boundary county whose table is **EST** (Eastern), it is mis-included in the Central
   feature → drop it (same surgery as the Fulton fix: edit the Central MultiPolygon's county
   list in the geojson). Counties whose table is genuinely **CST** stay.
4. Visual-verify the relevant GA tables from the crop; add a cross-check test per corrected
   county (birth in county X, 1919–1941, resolves EST not Central); `rake test`.
5. Log the outcome in DEFERRED.md #1 + COVERAGE.md Georgia.

### TASK 2 — Maine no-DST extension (page 229) — MEDIUM, needs care
Maine shipped PARTIAL: only ME#1/#2 crop-verified; no-DST towns → flat `Etc/GMT+5`, DST towns
defer (safe). We now classify all ~38 tables. Extend the `Etc/GMT+5` override to the towns of
every additional **NO-DST** table (rural, pure EST, no peacetime/postwar EDT rows).
⚠️ **CAVEAT**: Maine tables cite each other's zone as a tight `ME#N` token, and `ocr_tables`
currently DROPS those rows — so a table that looks "NO-DST" in the output may actually follow
another table via `ME#N`. **Crop-verify every ME table before tagging it no-DST.** Numbering
is ~90% correct (a few `~N` + one stray); confirm the number against the crop header too.
Steps: render+classify ME → list candidate NO-DST tables → crop-verify each → map their towns
via `map_counties.rb`/the ME index → add towns to the no-DST override set → cross-check test →
log. This is the same town-layer recipe used for the ME#1/#2 ship.

### TASK 3 — Illinois / Indiana (pages 128 / 150) — HIGH value, LARGE, multi-session
`ocr_tables` now supplies the **per-table DST label** that DEFERRED #9/#11 named as the missing
prerequisite ("each real table must be labeled CST-to-1959 vs early-DST"). The city→county→table
index is already clean (IL 96% / IN 86% of citations on real tables). So the OCR fight is over;
what remains is AUTHORING: reconcile each county → its IANA sub-zone and write synthetic zic for
the divergent patterns. This is a dedicated multi-session research pass, NOT a quick win — do it
only as a deliberate project (Shanks calls IN "contradictory"; wrong synthetic zones are worse
than the honest `warn`). Start by classifying all IL/IN tables and clustering counties by table
pattern; stop and reassess before authoring.

### TASK 4 — resume the alphabetical sweep
After the above, continue pending states at **Massachusetts (PDF 254)**, then the other pending
rows in COVERAGE.md (ND 393/405, SD 505, MS 292, OH 409, TX 531, WV 603, WI 617, …). For each:
render+classify, triage vs the index, and apply the flat-override-or-warn recipe with the gates.

## Suggested order
1 (GA) → 2 (ME) → 4 (resume sweep) as the steady cadence; schedule 3 (IL/IN) as its own project
when there's appetite for a multi-session authoring pass. Commit each task separately with a
crop-verified cross-check test; update DEFERRED.md + COVERAGE.md as you go.
