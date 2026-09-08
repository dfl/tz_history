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
| Alabama | 13 | ✓ | flat CST | **pending** | Check the real 1941 summer-DST episode (audit: al_dst_history.md). **← START HERE** |
| Arizona | ? | – | IANA? | pending | |
| Arkansas | 40 | ✓ | flat CST | pending | |
| California | ? | – | IANA? | pending | |
| Colorado | ? | – | IANA? | pending | |
| Connecticut | ? | – | IANA? | pending | |
| Delaware | ? | – | IANA? | pending | |
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

_(none yet)_
