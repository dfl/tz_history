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
| Colorado | 72 | – | IANA? | pending | **Residual found**: CO#1 (most counties) has NO 1920 DST, but IANA America/Denver applies a spurious 1920 Denver DST → rural-CO summer-1920 births read 1h fast. Needs county map (Denver-metro on CO#2 = IANA-ok). |
| Connecticut | 79 | – | IANA? | pending | **Residual found**: CT#1 has NO DST 1920–1925, but IANA America/New_York applies continuous NYC DST → non-metro CT summer 1920–1925 births read 1h fast. Fixable via flat Etc/GMT+5. Needs county map (Fairfield/NYC-metro = IANA-ok). |
| Delaware | 84 | – | IANA? | pending | Many tables (Philadelphia-metro early DST); needs analysis + county map. |
| Florida | 90 | ✓ | flat EST/CST | pending | peninsula/panhandle split (fl_dst_history.md) |
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

**Alabama:**
- `warn` (split, defer to IANA): Chambers (01017), Lee (01081), Russell (01113) —
  the east-Alabama Georgia-line counties that keep Eastern de facto (pre-existing
  warns; AL_1 deliberately excludes them, so they are NOT asserted as CDT in 1941).
- Left flat (NOT covered — standing summer-DST limitation): minority-table city DST
  that the statewide AL_1 does not model — AL #2 (summers 1958–1960) and AL #4 (1935,
  1940), likely Birmingham/Mobile metro one-off local DST. A birth in those specific
  city-years is under-corrected (reads CST where the city briefly observed CDT); not
  worth a per-county carve-out. AL_1 covers only the real *statewide* 1941 episode.
