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
| Georgia | 104 | ✓ | flat EST + CST-west | pending | **Atlanta 1937-39 residual** (canonical case) |
| Idaho | ? | – | IANA? | pending | |
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
