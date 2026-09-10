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

> **⚠ Authoritative TT pages are now `tools/atlas_pages.tsv`** (header-verified for all 48
> CONUS states via `tools/locate_states.rb`), NOT the "TT pg" column below, which holds
> drifted printed-page numbers for the PENDING states. Several are wrong: **LA 207→219**
> (the ledger's 207 is Kentucky's city listings), **MS 280→292, ND 393→405, OH 410→409,
> TX 519→531, WV 604→603, WI 605→617**; and the previously-unknown states are located:
> AZ 31, ME 229, MD 239, MA 254, MI 263, MN 281, MT 314, NV 325, NH 328, NJ 333, NM 345,
> NY 352, OR 439, PA 448, RI 494, UT 556, VT 560, WA 592, WY 627. The done states (13–200)
> are unaffected. Trust `atlas_pages.tsv`; confirm the header on first touch.

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
| Georgia | 104 | ✓ | flat EST + CST-west | **done** | Atlanta local DST **1937–1940** (Shanks GA #21, EDT — 4 yrs, not 3) fixed via exclusion guard over Fulton+DeKalb → defer to IANA. Dominant EST/Central overrides ship. **Fixed the Atlanta-metro Central bug** (see fallback log): Fulton+Cobb+Clayton+Cherokee+Forsyth dropped from the Western-GA Central set → now resolve statewide EST like DeKalb; 43 true-Central counties unchanged. **N/NE-mountain boundary counties resolved (2026-09, crop-verified PDF 104):** Union/Fannin/Gilmer/Lumpkin/Dawson/Pickens/Bartow all cite Shanks GA #8 = Central-no-DST until the 1941-03-21 switch to Eastern, so they are *correctly* Central pre-1941 (feat[40] window ends at the switch) and EST after — verified every indexed city; no change needed, 3 regression tests added. |
| Idaho | 122 | – | flat PST (N) + flat MST (SE) | **done** | 18 tables (ID #1–#18); two-zone state, resolved with a city→county→table majority map (44 counties, `tools/map_counties.rb`, visual-verified). **Shipped (2 flat overrides + 2 split counties):** (1) flat Etc/GMT+8 over the 10 north panhandle Pacific counties for 1945-09-30..1964-04-26 — dominant table ID #2 kept PST (no DST) 1946–1963 while IANA America/Los_Angeles applies California summer DST 1948 & 1950–1963. (2) flat Etc/GMT+7 over 13 eastern/central Mountain counties for 1919-10-26..1923-05-13 — they went Mountain in 1919 (ID #13–16) but IANA America/Boise stays Pacific until the official 1923-05-13 move. (3) Custer + Power resolved town-by-town via `split` features (nearest documented Shanks town → Mountain override for the eastern towns, defer for the western/southern Boise-match towns). Western/SW counties (Ada/Boise etc., ID #17/#18) match Boise exactly → defer. Residual minorities logged & deferred (see fallback log). |
| Illinois | 128 | ✓ | flat CST (downstate) | **done** | 100+ tables; resolved via a city→county→table majority map (`tools/map_counties.rb` over PDF 131–149, 102-county legend). **Shipped:** flat Etc/GMT+6 over the 95 downstate counties for two windows (1919-10-26..1942-02-09 and 1945-09-30..1959-07-01) — downstate kept CST (state law required CST birth records until 1959-07-01; dominant table IL #4 = pure CST 1919–1959) while IANA America/Chicago bakes in Chicago's continuous summer DST (CDT every year 1920–1966). Replaced the old coarse downstate "ambiguity" warn with the actual correction. The 7 Chicago-metro counties (Cook, DuPage, Kane, Kendall, Lake, McHenry, Will) defer to IANA via the pre-existing metro exclusion guard (they observed the DST). Town-by-town DST-adoption minorities logged & deferred (see fallback log). |
| Indiana | 150 | – | warn (statewide) | **done*** | The hardest state. Shanks: "very complex ... contradictory ... not documented." Central-zone (CST) portions observed summer DST; Eastern-zone (EST) portions did not; counties switched Central↔Eastern at poorly-documented dates 1940s–60s (whole state on DST only 1969–70). IANA's 8 America/Indiana/* sub-zones are best-guesses that disagree with Shanks tables in both directions. ***Shipped a statewide `warn` (90 counties, 1918–1970; the clean NW Chicago corner Lake+Porter excluded) that flags the ambiguity and defers to IANA — no override asserted. A real correction needs per-county Shanks-table × per-county IANA-sub-zone reconciliation + synthetic zic zones; logged in `docs/DEFERRED.md` as a dedicated future pass.** |
| Iowa | 183 | ✓ | flat CST + postwar warn | **done** | Entirely Central; 22 tables (IA #1–#22), all pure CST pre-war and through 1953 (crop-verified IA #1/#2/#3/#8/#12). **Shipped:** pre-war Etc/GMT+6 (1919-10-26..1942-02-09, pre-existing) **+ new postwar Etc/GMT+6 (1945-09-30..1954-04-25)** — 1946–1953 was universally CST (earliest postwar DST = IA #8, 1954) while IANA America/Chicago applies continuous CDT. Upgraded the front of the old postwar warn to this override; the warn now covers only the patchy 1954–1967 town-by-town period. IA #12 urban exception (DST 1941 + from 1957) logged. **Note: ledger "TT pg" was the printed page (171); Iowa TIME TABLES are PDF 183.** |
| Kansas | 192 | ✓ | flat CST + far-west warn | **done** | Entirely Central except the far west; 5 tables. **Verified** the pre-existing import coverage against the crop: KS #1 (dominant Central) is pure CST with no local DST 1920–1966 (only war time) → US#1 1967, so the shipped pre-war (1919-10-26..1942-02-09) + postwar (1945-09-30..1967-04-30) Etc/GMT+6 overrides are correct and universal (no Iowa-style scatter). Far-west: 4 IANA-Denver counties defer to IANA Mountain via a note-less exclusion guard ("IANA already correct"); 9 other far-west counties → warn (uncertain Mountain vs observed CST, Shanks: "estimated from incomplete information"). No new features needed; added 3 confirming tests. |
| Kentucky | 200 | ✓ | **Shanks #69/#71** + flat | **done** | Louisville→IANA guard; Campbell/Kenton→KY_71 |
| Louisiana | 219 | ✓ | flat CST + NOLA 1946 guard | **done** | Entirely Central; 2 tables (crop-verified, PDF 219). LA #1 (dominant, ~all parishes) is pure CST → US#1 1967; the pre-existing pre-war (1919-42) + postwar (1945-67) Etc/GMT+6 overrides are correct. **Added:** an exclusion guard over Orleans (22071), Jefferson (22051), St. Bernard (22087) for 1946-04-29..1946-09-29 — the New Orleans/lower-delta cluster (LA #2) observed CDT that one summer, which the statewide CST override otherwise flattens; the guard defers to IANA America/Chicago (correct CDT). Zone-2 parishes identified via `tools/map_counties.rb`. Plaquemines lower-delta split (majority CST) logged. |
| Maine | 229 | – | **town-level EST** | **done*** | Crop-verified ME #1 (dominant, 38%) = pure EST, NO peacetime DST 1920–1954 (war time excepted), while IANA America/New_York applies continuous NYC summer DST (EDT every summer 1920–1966). Maine was **town-by-town** (coastal/city towns observed DST, rural inland did not), so shipped a **TOWN-LEVEL split** (the city-specific approach): ~396 no-DST towns (ME #1, + ME #2 pre-war) → flat Etc/GMT+5 across all 16 counties; DST towns defer. ***EXTENDED (2026-09) to the full adoption-year cohort nest.** Crop-verified ALL 38 tables (PDF 229): every rural table follows ME #1 (EST) until it adopts US-standard DST in a specific year (1931/1932/1933/1934/1935/1936/1937/1938/1940/1941), after which it matches IANA. Replaced the single pre-war split with **7 non-overlapping adoption-year windows** (each town resolves EST until its table's adoption year, then defers) + regenerated postwar (ME #1 only). Coverage rose from ~396 towns EST to 923 (early window). Pre-1931 DST cities (ME #12/#13/#14/#16 — Portland/Bangor/Lewiston) defer throughout. Also fixed a city-listing OCR artifact: `extract_cities --max-table=38` dropped 230 bleed-misparsed towns (spurious table# 44/45/47 = latitude degrees) and a fresh re-scan raised the clean town→table index 792→959 towns. Never over-corrects (a table is EST only in windows entirely before its adoption). |
| Maryland | 239 | – | **town-level EST** | **done*** | Crop-verified all 8 major tables (PDF 239): **only MD #1 (greater Baltimore) observed peacetime DST 1920–41** (intro: "unofficially observed... seldom in official records... greater Baltimore... infrequent"); every other table (rural, ~98% of towns) kept EST while IANA America/New_York applies continuous NYC EDT. Shipped a **town-level split**: rural towns → Etc/GMT+5 (pre-war 1919-10-26..1942-02-09), Baltimore-area (MD #1) towns defer. 1755 towns corrected. **Postwar handled per-table** via non-overlapping windows: 1946 all rural EST; 1947 only MD #7/#16 (held out); 1948-1953 only MD #16 (EST to US#4 uniform 1954); most tables resumed DST in 1947 and defer after 1946. All 8 major tables + an OCR peacetime-EDT scan classified from the crop. |
| Massachusetts | 254 | – | **IANA + MA#2 split** | **done** | Only 2 tables. **MA #1 (681 towns, 98%)** = EST with continuous EDT every summer from 1920 → US#1 1967 = **exactly IANA America/New_York, no residual** (Boston's early continuous DST, which IANA bakes in, was genuinely statewide-dominant). **MA #2 (14 towns)** = rural western-MA hill towns (Franklin + Hampshire: Deerfield/Whately/Leverett/Ashfield/Sunderland/Southampton) that kept **EST with no DST in summers 1920 & 1921** (resumed DST 1922, US#1 1923) while IANA applies EDT — shipped a **town-level split** over Franklin+Hampshire (Etc/GMT+5 for MA #2 towns, 1920-04-25..1921-09-26; MA #1 valley towns + Boston defer). Same seaboard pattern as CT/CO/DE. Crop-verified PDF 254. |
| Michigan | 263 | – | **deferred (dedicated project)** | **probed/deferred** | Crop-verified MI #1 (dominant, 47%) = **Central until 1931-04-26, then Eastern** (vs IANA America/Detroit's 1915 Eastern switch) → a 1 h zone-level divergence 1915–1931 over ~half the state. Two-zone (western UP genuinely Central = America/Menominee), **100+ tables town-by-town**, contested 1920s switches (Shanks flags it). Same category as Indiana (#11 in DEFERRED): a dedicated multi-session authoring pass (county→switch-year clustering + synthetic transition zics), NOT safe to rush. **No override shipped — defers to IANA.** Logged in DEFERRED #14. |
| Minnesota | 281 | ✓ | flat CST | **done** | VERIFY-ONLY. Crop-verified MN #1 (1543 towns, **95%**) = straight CST, no local DST 1919–1957 (war excepted), adopting DST 1957-04-28 → US#1 1966, while IANA America/Chicago applies CDT every summer 1921–1957. The pre-existing import overrides (pre-war Etc/GMT+6 1919-10-26..1942-02-09 + postwar 1945-09-30..**1957-04-28**, window ends exactly at the 1957 adoption) are correct for the dominant table — confirmed, no new features; 2 confirming tests added. **Minority:** MN #3 (Twin Cities metro, 46 towns) observed CDT in isolated summers **1932 & 1946** (+ 1957 on) — over-corrected to CST those two summers (logged in DEFERRED); MN #5 (Duluth area) is NO-DST, covered correctly. |
| Mississippi | 292 | ✓ | flat CST | **done** | VERIFY-ONLY (PDF 292, printed 280). Crop-verified MS #1 (1423 towns, **99%**) = pure CST, NO peacetime DST at all (only war time 1918-19/1942-45) 1883→1967, then US#1 1967, while IANA America/Chicago applies CDT. Pre-existing import overrides (pre-war Etc/GMT+6 1919-10-26..1942-02-09 + postwar 1945-09-30..1967-04-30) confirmed correct; no new features; 2 confirming tests. **Minority:** MS #2 (Jackson/Hinds metro, 17 towns) observed CDT in a single summer **1935** — over-corrected to CST that one summer (logged in DEFERRED). |
| Missouri | 300 | ✓ | flat CST + postwar warn | pending | |
| Montana | 314 | – | **town-level MST split** | **done** | Crop-verified (PDF 314, printed 302): MT #1 (68%) + MT #9 (22%) = **90% of towns are pure MST, no peacetime DST 1919–1967** (war excepted; MT #9 only differs pre-1895 = Pacific), while IANA America/Denver applies MDT. Shipped a **town-level split** over all 56 counties (568 no-DST towns → Etc/GMT+7 for pre-war 1919-10-26..1942-02-09 + postwar 1945-09-30..1967-04-30; the ~10% metro DST tables MT #2/#3/#10 defer). Town-level (not flat) because the DST minority is large enough (postwar metros) that a flat override would over-correct. The big cities (Helena/Missoula/Butte) were themselves no-DST → MST. 3 tests. |
| Nebraska | 319 | ✓ | flat CST + far-west warn | pending | |
| Nevada | 325 | – | **eastern-Mountain split** | **done** | Crop-verified (PDF 325, printed 313): NV #1 (77%) = Pacific (PST→PDT from 1948) = America/Los_Angeles, **no residual**. The sparsely-populated eastern tables observed **MST while IANA models all Nevada as Pacific** (1 h zone divergence): NV #3 (12 towns) = MST throughout; NV #2 (25) = Pacific until 1930 then MST to 1967; NV #4 (19) = MST 1930–1965 then back to Pacific. Shipped a **3-window non-overlapping Mountain nest** over all 17 counties (a town is MST only while its table was Mountain → Etc/GMT+7; NV #1 defers). Shanks flags the eastern boundary as "undocumented," but each town's table resolves it. 4 tests. |
| New Hampshire | 328 | – | **rural-EST town split** | **done** | Crop-verified (PDF 328, printed 316): seaboard pattern. No NH table observed DST before 1931; the rural **NH #1 (67%)** kept EST until 1937, while the urban minority tables adopted DST 1931–1936, and IANA America/New_York applies continuous NYC DST from 1920. Shipped a 2-window town-level split over all 10 counties: **W1 [1919-10-26, 1931-04-26) all towns → Etc/GMT+5** (universally no-DST), **W2 [1931-04-26, 1937-05-11) only NH #1 → Etc/GMT+5** (urban towns defer — they had EDT). Fully correct for the main cohorts; tiny no-DST tables NH #10/#14 defer after 1931 (logged). 3 tests. (4 coastal-edge towns fall just outside the county polygon → negligible.) |
| New Jersey | 333 | – | **rural-EST cohort nest** | **done** | Crop-verified (PDF 333, printed 321): the urban tables **NJ #1/#6/#9/#11** had continuous DST from 1920 = IANA America/New_York, **no residual**. Rural tables kept EST with no DST until adopting US DST at staggered years — big: **NJ #2→1921** (211 towns), **NJ #17→1931** (269), **NJ #12→1937** (424); small tail #3/#7 (1922), #4 (1928), #5 (1930), #14 (1932), #8/#15 (1933), #16 (1934), #13 (1937) — while IANA applies NYC DST from 1920. Shipped a **3-window non-overlapping nest** over all 21 counties (boundaries 1921/1931/1937): a rural town resolves Etc/GMT+5 only in windows before its table's adoption, then defers. Handles NJ #2/#17/#12 exactly; small tail drops at the nearest boundary ≤ its adoption (safe under-correction, logged). 4 tests. |
| New Mexico | 345 | – | **flat MST** | **done** | Crop-verified (PDF 345, printed 333): NM #1 (887 towns, **98%**) = pure MST with no peacetime DST 1883→1967 (war excepted), then US#1 1967, while IANA America/Denver applies MDT every summer. NM #2/#3 (the tiny remainder) are also MST no-DST. Shipped a **flat statewide Etc/GMT+7 override** over all 33 counties (pre-war 1919-10-26..1942-02-09 + postwar 1945-09-30..1967-04-30), like Mississippi but Mountain. 2 tests. A negligible 1–2-town DST exception (~1953) is over-corrected (logged). |
| New York | 352 | – | **rural-EST cohort nest** | **done** | The largest state. **⚠ tt spans PDF 352-359 (8 pages, tables NY#1-226)** — the original atlas index mis-split (tt=352 only) and parsed 7 tt pages as junk "cities" (see DEFERRED systemic bug); re-OCR'd (tt 352-359 + cities 360-386, `--max-table=226`) → clean index 4817 towns. Crop-verified: **NY#1 = continuous EDT every summer from 1920 = exactly IANA America/New_York (NYC), no residual** (IANA applies NYC EDT every summer 1918-1968, baking it into the whole state). Rural upstate kept EST for years, adopting US DST at staggered dates. Dominant rural table **NY#226 (967 towns)** = EST via NY#4 through 1941 + EST 1946-1954, adopting DST only 1955; other big EST tables NY#11 (adopt 1931, 440t), #13 (1939, 289t), #7 (1925), #14 (1940), #6 (1923), #20 (1951). Shipped an **11-window non-overlapping cohort nest** (`research/builders/build_ny.rb`) over all 62 counties: a town gets Etc/GMT+5 only in windows where its Shanks table was EST for EVERY summer (per-table EST-year census, crop-verified for all tables ≥15 towns) → never over-corrects (summer 1920 & war 1942-45 excluded = IANA; early-DST-then-revert and blip tables auto-excluded from windows spanning their DST years). Covers ~2650 correctable towns. 8 tests. **Residual:** the long tail (~180 tables <15 towns, ~15% of towns) is not yet classified → defers to IANA (safe under-correction, logged in DEFERRED). |
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
- **✅ FIXED (2026-09, `feature/deferred-backfills`): Fulton (Atlanta) + Cobb/Clayton/
  Cherokee/Forsyth were wrongly in the Western-Georgia Central set** (the merged Etc/GMT+6
  feature + their standalone America/Chicago features, incl. the Fulton one), so Atlanta
  read CENTRAL 1919–1941 outside the 1937–40 guard — a 1 h error, since Shanks' Atlanta
  table (GA #21) is EASTERN. **Fix:** confirmed via the GA index which metro counties
  resolved Etc/GMT+6 (vs DeKalb/Gwinnett already Eastern), dropped those 5 counties'
  polygons from the merged Central feature and deleted their 5 per-county Central features,
  so they fall through to the statewide GA Eastern override (Etc/GMT+5) like DeKalb. The
  43 genuinely-Central counties (Columbus/Muscogee, LaGrange/Troup, …) are unchanged. The
  geojson was normalised to compact-geometry-per-feature in the process (un-exploding the
  old #40). Regression tests assert Atlanta-metro→EST and true-western-GA→CST for 1925.
  **Note:** the N/NE-mountain boundary counties (Union/Fannin/Gilmer/Lumpkin/Dawson/
  Pickens/Bartow) may still be over-included — they need the GA TIME-TABLES crop to map
  table→zone (the index's per-city table# doesn't encode Central vs Eastern by number);
  logged in DEFERRED.md for a follow-up crop-verified pass.

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
