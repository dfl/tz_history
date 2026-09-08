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
| Idaho | 122 | – | flat PST (N) + flat MST (SE) | **done** | 18 tables (ID #1–#18); two-zone state, resolved with a city→county→table majority map (44 counties, `tools/map_counties.rb`, visual-verified). **Shipped (2 flat overrides + 2 split counties):** (1) flat Etc/GMT+8 over the 10 north panhandle Pacific counties for 1945-09-30..1964-04-26 — dominant table ID #2 kept PST (no DST) 1946–1963 while IANA America/Los_Angeles applies California summer DST 1948 & 1950–1963. (2) flat Etc/GMT+7 over 13 eastern/central Mountain counties for 1919-10-26..1923-05-13 — they went Mountain in 1919 (ID #13–16) but IANA America/Boise stays Pacific until the official 1923-05-13 move. (3) Custer + Power resolved town-by-town via `split` features (nearest documented Shanks town → Mountain override for the eastern towns, defer for the western/southern Boise-match towns). Western/SW counties (Ada/Boise etc., ID #17/#18) match Boise exactly → defer. Residual minorities logged & deferred (see fallback log). |
| Illinois | 128 | ✓ | flat CST (downstate) | **done** | 100+ tables; resolved via a city→county→table majority map (`tools/map_counties.rb` over PDF 131–149, 102-county legend). **Shipped:** flat Etc/GMT+6 over the 95 downstate counties for two windows (1919-10-26..1942-02-09 and 1945-09-30..1959-07-01) — downstate kept CST (state law required CST birth records until 1959-07-01; dominant table IL #4 = pure CST 1919–1959) while IANA America/Chicago bakes in Chicago's continuous summer DST (CDT every year 1920–1966). Replaced the old coarse downstate "ambiguity" warn with the actual correction. The 7 Chicago-metro counties (Cook, DuPage, Kane, Kendall, Lake, McHenry, Will) defer to IANA via the pre-existing metro exclusion guard (they observed the DST). Town-by-town DST-adoption minorities logged & deferred (see fallback log). |
| Indiana | 150 | – | warn (statewide) | **done*** | The hardest state. Shanks: "very complex ... contradictory ... not documented." Central-zone (CST) portions observed summer DST; Eastern-zone (EST) portions did not; counties switched Central↔Eastern at poorly-documented dates 1940s–60s (whole state on DST only 1969–70). IANA's 8 America/Indiana/* sub-zones are best-guesses that disagree with Shanks tables in both directions. ***Shipped a statewide `warn` (90 counties, 1918–1970; the clean NW Chicago corner Lake+Porter excluded) that flags the ambiguity and defers to IANA — no override asserted. A real correction needs per-county Shanks-table × per-county IANA-sub-zone reconciliation + synthetic zic zones; logged in `docs/DEFERRED.md` as a dedicated future pass.** |
| Iowa | 183 | ✓ | flat CST + postwar warn | **done** | Entirely Central; 22 tables (IA #1–#22), all pure CST pre-war and through 1953 (crop-verified IA #1/#2/#3/#8/#12). **Shipped:** pre-war Etc/GMT+6 (1919-10-26..1942-02-09, pre-existing) **+ new postwar Etc/GMT+6 (1945-09-30..1954-04-25)** — 1946–1953 was universally CST (earliest postwar DST = IA #8, 1954) while IANA America/Chicago applies continuous CDT. Upgraded the front of the old postwar warn to this override; the warn now covers only the patchy 1954–1967 town-by-town period. IA #12 urban exception (DST 1941 + from 1957) logged. **Note: ledger "TT pg" was the printed page (171); Iowa TIME TABLES are PDF 183.** |
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

> **Deferred residuals / known limitations are indexed in [`docs/DEFERRED.md`](DEFERRED.md)** —
> a cross-state backlog (minorities, transitions, the Georgia Fulton bug) for a second pass.
> When you defer something here, add a row there too.

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

**Idaho:** (18 tables; two-zone — Pacific north panhandle + Mountain south. Resolved
with a city→county→table majority map, `tools/map_counties.rb` over PDF 122–127,
visual-verified against the CITY LISTINGS. Shanks numbers counties alphabetically 1–44
= modern Idaho's 44 counties exactly, no modern-only county.)

*North — `override` Etc/GMT+8 (PST, no DST 1945-09-30..1964-04-26):* the 10 panhandle
Pacific counties — Benewah (16009), Bonner (16017), Boundary (16021), Clearwater
(16035), Idaho (16049), Kootenai (16055), Latah (16057), Lewis (16061), Nez Perce
(16069), Shoshone (16079). The dominant table by majority vote is ID #2 (PST 1946–1963,
DST from 1964); IANA America/Los_Angeles wrongly applies California DST 1948 & 1950–1963.
Window ends 1964-04-26 (the 1964 DST season the panhandle did observe).

*South — `override` Etc/GMT+7 (MST, no DST 1919-10-26..1923-05-13):* the 13 eastern/
central Mountain-from-1919 counties — Bannock (16005), Bear Lake (16007), Bingham
(16011), Bonneville (16019), Butte (16023), Caribou (16029), Clark (16033), Franklin
(16041), Fremont (16043), Jefferson (16051), Lemhi (16059), Madison (16065), Teton
(16081) — majority ID #13–16 (Mountain from 1919). IANA America/Boise stays Pacific
until the official 1923-05-13 move, so 1920–22 births read 1h slow. Window starts
1919-10-26 (after the 1919 national daylight, when they were cleanly MST).

*South — `split` (1919/1923 straddle, resolved town-by-town):* Custer (16037) and
Power (16077) split roughly evenly between Mountain-from-1919 and Boise-match cities
(Custer 18:7/16:6, Power 18:9/14:4). Rather than a whole-county warn, these ship a
`split` feature that embeds the Shanks CITY LISTINGS points (name/lat/lon/zone, from
the 300-dpi extraction) and snaps a birth to the nearest documented town: eastern
towns (Custer's Lost River valley — Mackay/Leslie/Houston/Dickey/Chilly; Power's
American Falls area — Michaud/Don/Crystal) → flat Etc/GMT+7 for 1919-10-26..1923-05-13;
western/southern Boise-match towns → defer to IANA. The note names the resolving town
so the birth town can be verified. This is the first use of the `split` feature kind
(see `Lookup#resolve_split`); the geographic split was crop-verified (Challis/Mackay,
Arbon/Michaud). Boundary towns not in Shanks (e.g. the town of American Falls itself)
snap to their nearest listed neighbour — no worse than the old whole-county warn.

*IANA-ok (defer, no feature):* the western/SW/south-central counties whose cities map
to ID #17/#18 (Mountain from 1923-05-13 = exactly what America/Boise models). Includes
Ada/Boise — the capital and largest southern city — Adams, Blaine, Boise, Camas, Canyon,
Cassia, Elmore, Gem, Gooding, Jerome, Lincoln, Minidoka, Oneida, Owyhee, Payette, Twin
Falls, Valley, Washington. ID #18 matches Boise offset-for-offset.

Deferred minorities (logged, not shipped):
- **North 1965 + within-county 1961-resumers**: the dominant #2 override ends
  1964-04-26; the dominant pattern was PST again in summer 1965 (IANA gives PDT → 1h
  fast), left uncorrected (one summer, low value). Conversely the minority panhandle
  cities on ID #1/#4/#7/#10/#12 (resumed DST in 1961) are over-corrected to PST for
  1961–63 by the majority-vote override — accepted minority (like CO/CT/DE).
- **North pre-war local DST (1931–1941)**: ID #3/#6/#8/#9/#10/#11 cities observed
  scattered summer PDT in 1931 and 1933–1941 that America/Los_Angeles (no DST then)
  omits → those city-summers read 1h slow under IANA. Opposite sign to the shipped fix
  and untouched by it (override starts 1945-09-30). Also ID #7 (1952) / ID #9 (1950)
  single postwar DST summers are under-corrected by the flat PST override. Deferred.
- **South postwar MDT**: ID #13/#17 observed MDT 1961–63 and ID #15 in 1964–65 that
  America/Boise omits — but NONE of these is a county majority (they appear only as
  scattered minority city votes), so no county qualifies for a postwar-MDT override.
  Deferred as a per-city minority.
- **South 1919 daylight sliver**: the Mountain-from-1919 override starts 1919-10-26, so
  Jan–Oct 1919 (the switch itself + that summer's national daylight, MWT) is left to
  IANA. A fraction of one year, tiny volume; would need a transition zone, not a flat
  override. Deferred.

**Illinois:** (100+ tables; a Central state where the residual is Chicago's continuous
DST baked into the whole-state IANA zone. Resolved with a city→county→table majority
map, `tools/map_counties.rb` over PDF 131–149; 102-county legend on PDF 132. Shanks'
intro: birth times were legally recorded in CST until 1959-07-01.)
- `override` Etc/GMT+6 (CST, no DST) two windows — 1919-10-26..1942-02-09 and
  1945-09-30..1959-07-01 — over the **95 downstate counties** (all but the 7 Chicago-
  metro counties below). Dominant downstate table is IL #4 (pure CST 1919→1959 US#2).
  IANA America/Chicago applies Chicago's continuous summer CDT (verified: −5 every Jul
  1918–1966), so downstate summer births read 1h fast; the flat CST override corrects
  them. War years (1942–1945 CWT) are left to IANA (both observed CWT), hence the split.
- `warn`/exclusion guard (pre-existing, kept): the 7 Chicago-metro counties — Cook
  (17031), DuPage (17043), Kane (17089), Kendall (17093), Lake (17097), McHenry (17111),
  Will (17197) — defer to IANA (they observed the continuous DST IANA models). This
  note-less guard is priority 0, so it wins over the downstate override for any overlap.
- **Replaced**: the old coarse single-polygon "Illinois downstate DST ambiguous — verify"
  warn (which merely flagged and deferred the whole downstate) with the actual CST
  correction above.
- **Deferred minorities (logged)**: DST adoption downstate was genuinely town-by-town —
  some larger towns observed local CDT in the 1930s (IL #14 etc.), some adopted DST in
  1946 (IL #7) or scattered across the 1950s (IL #8/#50/#55…), ahead of the 1959 law
  change. The flat CST override (majority vote: dominant IL #4 kept CST to 1959)
  over-corrects those specific town-summers to CST. Also LaSalle County (Ottawa, ~15%
  Chicago-DST cities) is included in the downstate override by majority vote. These are
  accepted majority-vote minorities; a birth in a known early-DST downstate town in a
  summer should be spot-verified. Note also: even where clocks ran CDT, Illinois birth
  *records* used CST until 1959 by law, which limits the real-world harm.

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
