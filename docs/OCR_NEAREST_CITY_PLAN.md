# Plan — full-atlas OCR + nearest-city ("split") resolution

Status: proposed (2026-09). Prereqs proven on Idaho (see the `split` feature kind in
`lib/tz_history/lookup.rb` and Custer/Power in `docs/COVERAGE.md`). This is the scale-up
of two things we validated ad-hoc during Idaho:

1. A repeatable OCR recipe that recovers **coordinates** from the CITY LISTINGS (not
   just the noisy TIME-TABLE drafts we had before).
2. A `split` feature that snaps a birth to the **nearest documented Shanks town** so a
   genuinely town-split county gets per-sub-region answers instead of a whole-county warn.

The point: turn the per-state visual grind into a **data pipeline** (OCR once, query
many times) *without* dropping the visual-verify / majority-vote gates that keep us
from shipping silent 1-hour errors.

---

## 0. The proven recipe (hard-won; do not rediscover)

Ad-hoc settings that actually work, learned on Idaho pages 122–127:

- **Render at 300 DPI**, grayscale (`pdftoppm -r 300 -png -gray`). 150 DPI loses the
  small-caps `N`/`W` and the `MM'SS` coordinate punctuation; 300 recovers `42N56'39`.
- **Crop to the page's REAL column count**, not a fixed 6. City listings are **3**
  columns; TIME TABLES are ~5. A 6-way crop slices through mid-entry coordinates — that
  was why the 150-dpi/6-col attempts returned zero coords.
- **Tile each column into vertical BANDS (~2400 px, ~200 px overlap).** A full-height
  300-dpi column (≈3240×12047) makes tesseract exit 1 with an empty result ("300
  chokes"). Band it.
- **Write crops to the scratchpad, NEVER `/tmp`.** The sandbox gives `/tmp` per-call
  isolation, so a crop written in one step is unreadable in the next (silent empty OCR).
- **Tolerant coordinate parser.** OCR fuses/doubles: `50'15`→`5015`, `N`→`Nn`, stray
  `s` for `w`. Parse `DD[N]MM['SS]` / `DDD[W]MM['SS]` with optional apostrophe and
  fused 3–4 digit minute+second tokens. See `frac()` in the Idaho `extract2.rb`.
- **Handle wrapped rows.** Long names wrap: `Aberdeen Junction 6` on one line, then
  `16 43N13'23 112w28'12` on the next. A stateful parser must join `name+county` with a
  following `table+coords` line.
- **OCR is still a draft.** Table numbers and county numbers survive OCR well (majority
  vote is robust); coordinates are good-but-not-perfect. Every authored zone still passes
  the visual-verify crop read + the SHANKS↔IANA cross-check (or hand assertions).

---

## Phase 1 — one-time full render + OCR into a git-ignored index

Goal: a structured, local, **git-ignored** research index for the whole atlas.

Outputs (per state, JSON, under a scratchpad/derived dir — NOT committed):
- `timetables[state] = { "ID_1": [ {at_local, off, dst, uniform}, ... ], ... }`
  (the transition lists — what `triage.rb` consumes).
- `cities[state] = [ {name, county_num, table, lat, lon}, ... ]`
  (the CITY LISTINGS index — what `map_counties`/nearest-city consume).
- `legend[state] = { county_num => name }` (the COUNTIES legend).

Tasks:
1. **Upgrade `tools/render_state.rb`**: 300 DPI, layout-aware column count
   (param, default detect), band tiling, scratchpad output.
2. **Upgrade `tools/ocr_tables.rb`**: consume the banded crops; keep the table-flow
   logic; emit `timetables[state]`.
3. **New `tools/extract_cities.rb`** (promote the Idaho scratchpad prototype): emit
   `cities[state]` + `legend[state]` with the tolerant coord parser + wrap handling.
4. **Locate each state** by header-OCR (render top 12% at 60 dpi, grep the caps) to get
   PDF page ranges — the ledger's page column seeds most; verify per the GA lesson
   (page indices drift when a state's county section is long).
5. Run across the atlas. Spot-check a few states against the rendered crop.

Copyright / storage:
- The atlas is copyrighted (RUNBOOK: "facts only, local, uncommitted"). The OCR **text
  corpus** stays a **git-ignored local artifact**. Timezone *facts* (dates/offsets/coords
  we author into zones/features) are not copyrightable and ship as usual.
- **Reuse, don't regenerate, the analysis:** the harmonic-explorer
  `research/historical_zones/*_dst_history.md` audits + `OLSON_CROSSCHECK.md` are
  hand-written analysis for ~24 states — carry them forward; they anchor each state's
  residual. The KY `pg20*_ky_cities.txt` already holds a coord city-index (187 rows) —
  reuse as a free cross-check against our re-extraction.

Exit criterion: for every CONUS state, `timetables`/`cities`/`legend` parse and a random
crop spot-check matches.

---

## Phase 2 — generalize nearest-city ("split") to all split counties

The `split` feature kind already exists (`Lookup#resolve_split`, shipped for Idaho
Custer/Power). Phase 2 applies it wherever a county genuinely splits **geographically**.

Decision rule per county (unchanged majority-vote spine, with a new third branch):
1. **Clear majority table** (share ≥ ~0.75) → single override/defer as today.
2. **No majority AND the minority tables differ by GEOGRAPHY** (towns on table A cluster
   on one side, table B on the other) → **`split`**: embed the towns, snap to nearest.
3. **No majority AND the split is NON-geographic** (e.g. by town *size*/DST-adoption
   date, like the north-Idaho 1961-vs-1964 tail) → keep a **warn** (nearest-city can't
   help; flag + note).

Guardrails:
- **Only for split counties.** Clean counties keep their simple single override — do not
  add per-town points everywhere (needless data + noise-amplification).
- **Snap within the matched county** (the polygon gate already ensures this; keep one
  `split` feature per county so a point can't snap across a county line).
- **Boundary towns not in Shanks** snap to their nearest listed neighbour — acceptable,
  and never worse than the whole-county warn it replaces. Say so in the note (it already
  names the resolving town).
- **Input is a city centroid** (confirmed in harmonic-explorer: geocoder → one lat/lon
  per town). So nearest-town is well-matched to the input; it is NOT rooftop precision.

Tooling:
- `tools/map_counties.rb` already votes county→table. Add a mode that also emits, for
  split counties, the per-town `{name,lat,lon,table→zone}` list for a `split` spec.
- `tools/add_feature.rb` already accepts `cities` (added for Idaho).
- Verify each split's geographic separability by reading the crop (as done for
  Custer/Power) before shipping — a `split` that isn't actually geographic must fall
  back to a warn.

---

## Sequencing

1. Phase 1 tooling upgrades (render/ocr/extract) — do once, reused forever.
2. Full render+OCR pass → the index. (Background-render; ~1 pg/s.)
3. Resume the alphabetical state sweep (next pending after Iowa), now triaging against
   the **index** instead of re-rendering each state; apply the Phase-2 decision rule.
4. Backfill `split` on already-done states only where a logged warn was actually a
   geographic straddle (candidates: any "town-by-town" warn — e.g. Delaware Kent,
   Connecticut urban counties — check whether those splits are geographic or by
   city-size before converting).

## Risks / non-goals

- Nearest-city does NOT fix non-geographic disagreements (DST-adoption-date splits).
  Those stay warns/deferred.
- Bulk OCR does NOT remove the visual-verify gate; it front-loads the drafts.
- Do not commit the OCR text corpus. Do not `JSON.pretty_generate` the geojson.
