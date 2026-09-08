# Coverage ledger

One row per CONUS state, worked **alphabetically**. A fresh session resumes at the
first `pending` row. See `docs/RUNBOOK.md` for the per-state procedure.

Status values:
- **done** — qualifying Shanks tables shipped (or confirmed none needed), tests green, closed out.
- **pending** — not yet processed. `flat` = a flat-offset override already ships (from
  harmonic-explorer); `IANA?` = no dataset entry yet (likely IANA-sufficient, still verify).

"TT pg" = PDF page of the TIME TABLES (printed page + 12). "OCR" = raw TIME-TABLE OCR
already in `harmonic-explorer/research/historical_zones/atlas_ocr/`. Fill unknown pages
by locating the state in the atlas (alphabetical) on first touch.

| State | TT pg | OCR | Ships today | Status | Shanks tables / notes |
|-------|------:|:---:|-------------|--------|-----------------------|
| Alabama | 13 | ✓ | flat CST + AL#7 warn | **done** | **Shanks AL_1**: statewide 1941 summer DST (Jul 21–Oct 1, CDT) over 64 counties; flat CST windows + Georgia-line warn (Chambers/Lee/Russell) unchanged. Minority city-DST tables left flat (see fallback log). |
| Arizona | ? | – | IANA? | pending | |
| Arkansas | 40 | ✓ | flat CST | **done** | Single statewide table; crop-verified clean CST (only WWI/war/uniform, all IANA-modeled). No residual — flat/IANA sufficient. |
| California | 52 | – | IANA? | **done** | Single statewide table; crop-verified. IANA America/Los_Angeles matches (1948 DST season + no pre-war DST). Flat/IANA sufficient. |
| Colorado | 72 | – | IANA? | **done** | Flat Etc/GMT+7 over 58 rural counties for 1919-10-26..1921-05-22, correcting IANA's spurious Denver 1920/1921 DST. Denver+Arapahoe → IANA-ok (had the DST). Adams/Douglas/Jefferson (+modern Broomfield) → warn. County map by majority vote. |
| Connecticut | 79 | – | IANA? | **done** | Flat Etc/GMT+5 over rural counties (Litchfield/Middlesex/Tolland/Windham) for 1919-10-26..1926-04-25, correcting IANA's spurious NYC 1920–25 summer DST. Urban counties (Fairfield/Hartford/New Haven/New London) → warn (city-by-city split). County map by majority vote (tools/map_counties.rb). |
| Delaware | 84 | – | IANA? | **done** | Town-by-town DST chaos. Sussex (rural south) → flat Etc/GMT+5 for 1919-10-26..1942-02-09 (no DST 1920–41 vs IANA's continuous EDT). Kent → warn (~50/50 split). New Castle (Wilmington metro) → IANA-ok (continuous DST). |
| Florida | 90 | ✓ | flat EST/CST | **done** | Dominant no-DST overrides already ship + crop-verified (FL#1 panhandle CST, FL#5 peninsula EST); resolve correctly vs IANA's summer DST. Two residuals logged & deferred (see fallback log): pre-1919 peninsula-Central, minority post-war local-DST counties. |
| Georgia | 104 | ✓ | flat EST + CST-west | **done*** | Atlanta local DST **1937–1940** (Shanks GA #21, EDT — 4 yrs, not 3) fixed via exclusion guard over Fulton+DeKalb → defer to IANA. Dominant EST/Central overrides already ship. ***Uncovered a pre-existing bug (see fallback log): Fulton is wrongly in the Western-GA Central set → Atlanta mis-zoned Central 1919–41 outside the guard; flagged for a dedicated geometry fix.** |
| Idaho | 122 | – | flat PST (north) | **done*** | 18 tables (ID #1–#18). **Shipped:** flat Etc/GMT+8 over the 10 north panhandle Pacific counties for 1945-09-30..1961-04-30 — they kept PST year-round (no DST) while IANA America/Los_Angeles applies California summer DST 1948 & 1950–1960 (1h-fast residual, universal across ID #1–12). ***Southern (Mountain, ID #13–18) deferred — needs a per-county switch-date map and is town-by-town (see fallback log): S-Idaho went Mountain in 1919 but America/Boise only switches 1923-05-13 (1919–1923 residual), plus scattered postwar MDT. Also deferred: north pre-war local DST (1931–41) and the 1961–65 DST-resumption tail.** |
| Illinois | 116 | ✓ | warn (downstate) | pending | Chicago continuous DST; downstate warn only |
| Indiana | ? | – | IANA? | pending | notoriously patchy — expect real work |
| Iowa | 171 | ✓ | flat CST | pending | |
| Kansas | 192 | ✓ | flat CST + far-west warn | pending | |
| Kentucky | 200 | ✓ | **Shanks #69/#71** + flat | **done** | Louisville→IANA guard; Campbell/Kenton→KY_71 |
| Louisiana | 207 | ✓ | flat CST | pending | |
| Maine | ? | – | IANA? | pending | |
| Maryland | ? | – | IANA? | pending | |
| Massachusetts | ? | – | IANA? | pending | |
| Michigan | ? | – | warn (west LP) | pending | piecemeal LP switch |
| Minnesota | ? | – | flat CST | pending | mn_dst_history.md |
| Mississippi | 280 | ✓ | flat CST | pending | |
| Missouri | 300 | ✓ | flat CST + postwar warn | pending | |
| Montana | ? | – | IANA? | pending | |
| Nebraska | 319 | ✓ | flat CST + far-west warn | pending | |
| Nevada | ? | – | IANA? | pending | |
| New Hampshire | ? | – | IANA? | pending | |
| New Jersey | ? | – | IANA? | pending | |
| New Mexico | ? | – | IANA? | pending | |
| New York | ? | – | IANA? | pending | NYC continuous DST likely |
| North Carolina | 387 | ✓ | flat EST | pending | |
| North Dakota | 393 | ✓ | flat CST + Mountain-west guard | pending | |
| Ohio | 410 | ✓ | flat EST + SW-Ohio Central | pending | Cincinnati/Hamilton residual |
| Oklahoma | 432 | ✓ | flat CST | pending | |
| Oregon | ? | – | IANA? | pending | |
| Pennsylvania | ? | – | IANA? | pending | |
| Rhode Island | ? | – | IANA? | pending | |
| South Carolina | 496 | ✓ | flat EST | pending | |
| South Dakota | 505 | ✓ | flat CST + Mountain-west guard | pending | |
| Tennessee | 510 | ✓ | flat CST/EST + East-TN switch | pending | |
| Texas | 519 | ✓ | flat CST + El Paso guard | pending | |
| Utah | ? | – | IANA? | pending | |
| Vermont | ? | – | IANA? | pending | |
| Virginia | 566 | ✓ | flat EST + postwar warn | pending | |
| Washington | ? | – | IANA? | pending | |
| West Virginia | 604 | ✓ | flat EST + postwar warn | pending | |
| Wisconsin | 605 | ✓ | flat CST + early-fringe warn | pending | |
| Wyoming | ? | – | IANA? | pending | |

Alaska / Hawaii: out of scope for now (single modern zones; add only if a birth-data need appears).

## Fallback log

Record majority-vote counties and genuinely-split (`warn`) counties here as they come
up, so partial coverage is never mistaken for complete coverage.

**Georgia:**
- `warn`/exclusion guard (note-less, priority 0) over Fulton (13121) + DeKalb (13089)
  for 1937-01-01..1941-01-01: the city of Atlanta observed local summer DST 1937–1940
  (Shanks GA #21, EDT), which IANA models; the guard blocks the statewide EST override
  so those years defer to IANA. Dominant statewide-EST (#269/270) + Western-GA Central
  (#40–88) overrides already ship.
- **⚠ PRE-EXISTING BUG uncovered (needs dedicated fix): Fulton County (Atlanta) is
  wrongly included in the Western-Georgia Central set** (feature #40, the merged
  Etc/GMT+6 no-DST set, AND feature #80, a standalone Fulton America/Chicago feature).
  So Atlanta resolves to CENTRAL time for 1919–1941 outside the 1937–40 guard window —
  a 1–2 h error — even though Shanks' own Atlanta table (GA #21) is EASTERN. Likely
  other Atlanta-metro / N-GA counties (Cobb, Clayton, Cherokee…) are similarly
  over-included. NOT fixed here: #40's geometry is fully pretty-printed (exploded), so
  removing Fulton needs targeted feature-block surgery (re-emit #40/#80 with compact
  geometry + corrected county list) or the boundary re-adjudicated — a dedicated pass,
  not safe to rush. The 1937–40 guard is a strict improvement in the meantime.

**Idaho:** (18 tables; a two-zone state — Pacific north panhandle + Mountain south)
- `override` Etc/GMT+8 (PST, no DST 1945-09-30..1961-04-30): the 10 north panhandle
  counties — Benewah (16009), Bonner (16017), Boundary (16021), Clearwater (16035),
  Idaho (16049), Kootenai (16055), Latah (16057), Lewis (16061), Nez Perce (16069),
  Shoshone (16079). All 12 Pacific tables (ID #1–12) were PST year-round from war's end
  until DST resumed in 1961; IANA America/Los_Angeles wrongly applies California DST in
  1948 and 1950–1960. Blanket flat override is safe (residual is universal across the
  north) — no city→table map needed.
- **Deferred residual — north 1961–1965 DST-resumption tail**: the panhandle cities
  split on *when* they resumed DST — ID #1/#4/#7/#10/#12 resumed 1961 (override ends
  1961-04-30, then IANA is correct), but ID #2/#3/#5/#6/#8/#9/#11 resumed only 1964, so
  their 1961–63 and 1965 summers stay under-corrected (read 1h fast vs the PST they
  actually kept). Ending the override at 1961-04-30 is the SAFE choice — extending it
  would over-correct the early-resumer counties. Per-city, low-volume; deferred.
- **Deferred residual — north pre-war local DST (1931–1941)**: ID #3/#6/#8/#9/#10/#11
  observed scattered summer PDT in 1931 and 1933–1941 that America/Los_Angeles (no DST
  then) omits, so those specific city-summers read 1h *slow* under IANA. Opposite sign
  to the shipped fix and not made worse by it (the override starts 1945-09-30). Also
  ID #7's summer 1952 PDT is under-corrected by the flat PST override (single city, one
  summer; accepted minority). Deferred.
- **Deferred — SOUTHERN Idaho (Mountain, ID #13–18) entirely**: needs a per-county
  switch-date map (the CITY LISTINGS) and is genuinely town-by-town. IANA America/Boise
  runs Pacific until 1923-05-13 then Mountain (US rules, no DST 1923–66). But Shanks
  shows south Idaho switched to Mountain much earlier and unevenly: ID #13/#14 on
  1919-01-01, ID #15/#16 on 1919-06-01 (→ a **1919–1923 residual**, IANA reads 1h slow),
  while ID #17/#18 switched 1923-05-13 (match Boise). Plus scattered postwar MDT that
  Boise omits: ID #13/#17 in 1961–63, ID #15 in 1964–65. A blanket south override would
  be WRONG (it would force the #17/#18 counties onto Mountain when they were still
  Pacific pre-1923). ID #18 matches Boise exactly (no residual). Low birth volume for
  the 1919–23 window (sparse rural, transitional zone); revisit if a south-Idaho
  pre-1923 birth needs it.

**Florida:** (dominant no-DST overrides already shipped from the prior audit; verified)
- Deferred residual 1 — **pre-1919 peninsula was Central**: the FL peninsula ran CST
  until it switched to Eastern on 1919-01-01, but IANA models it as America/New_York
  (Eastern) back to 1883, so pre-1919 peninsula births read 1h fast. NOT a clean flat
  fix: the peninsula observed WWI 1918 daylight as CWT (−05) before the switch, so a
  correct fix needs a transition zone, not a flat Etc/GMT+6. Deferred (low pre-1919
  volume); revisit if a pre-1919 FL birth needs it.
- Deferred residual 2 — **minority post-war local-DST counties**: FL #2/#3/#4 (Central)
  observed CDT in scattered 1931/1941/1946–65 summers and FL #6 (Eastern) EDT in 1946;
  the dominant flat override over-corrects those specific county-summers to standard.
  Standing summer-DST limitation (scattered, low-impact); dominant no-DST matches
  FL #1/#5.

**Delaware:**
- `override` Etc/GMT+5 (no DST 1920–41): Sussex (10005).
- `warn` (~50/50 town split): Kent (10001).
- `IANA-ok`: New Castle (10003) — Wilmington metro, continuous DST from 1920. Its
  ~29% rural no-DST towns are an accepted minority limitation (majority vote).
- Table taxonomy: DE #1 = continuous DST 1920–41 (IANA-ok); DE #2–16 = no DST 1920–41
  (rural variants differing only in when they later adopted DST, ~1946–53).

**Colorado:**
- `override` Etc/GMT+7 (majority table CO #1, no DST 1920–21): 58 rural/mountain
  counties.
- `warn` (Denver-metro straddle): Adams (08001), Douglas (08035), Jefferson (08059),
  plus modern Broomfield (08014, carved 2001 from these + Boulder/Weld).
- `IANA-ok` (had the 1920 DST, no feature): Arapahoe (08005), Denver (08031).
- **Gotcha logged**: Colorado has 64 modern counties but Shanks has 63 — Broomfield
  (08014) was created in 2001. Map Shanks county# → county by NAME (Shanks numbers
  alphabetically), never by modern FIPS index, or the metro counties shift by one.

**Connecticut:**
- `override` Etc/GMT+5 (majority table CT #1, no DST 1920–25): Litchfield (09005),
  Middlesex (09007), Tolland (09013), Windham (09015).
- `warn` (genuine urban/rural DST split — big city on DST from 1920, towns from 1926):
  Fairfield (09001), Hartford (09003), New Haven (09009), New London (09011).
- Table taxonomy: CT #1 = no DST 1920–25; CT #2 = DST every year (IANA-ok);
  CT #3 = DST 1920 only then none 1921–25. Minority table-3 cities in the override
  counties are under-corrected for summer 1920 only (accepted; majority vote).

**Alabama:**
- `warn` (split, defer to IANA): Chambers (01017), Lee (01081), Russell (01113) —
  the east-Alabama Georgia-line counties that keep Eastern de facto (pre-existing
  warns; AL_1 deliberately excludes them, so they are NOT asserted as CDT in 1941).
- Left flat (NOT covered — standing summer-DST limitation): minority-table city DST
  that the statewide AL_1 does not model — AL #2 (summers 1958–1960) and AL #4 (1935,
  1940), likely Birmingham/Mobile metro one-off local DST. A birth in those specific
  city-years is under-corrected (reads CST where the city briefly observed CDT); not
  worth a per-county carve-out. AL_1 covers only the real *statewide* 1941 episode.
