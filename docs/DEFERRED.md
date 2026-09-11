# Deferred residuals & known limitations

A consolidated backlog of everything the state-by-state sweep (see `docs/COVERAGE.md`)
found but deliberately did **not** ship — majority-vote minorities, transitional slivers,
pre-existing bugs, and residuals that need more than a flat override. Each state's
`docs/COVERAGE.md` fallback log has the full prose; this file is the cross-state index so
we can prioritise a second pass without re-reading every state.

**Legend — Type:** `minority` = a majority-vote override under/over-corrects a known
subset of towns/years · `bug` = a shipped feature is wrong and needs a fix ·
`transition` = needs a synthetic transition zone (a flat override can't express it) ·
`sliver` = tiny window/population, low value.
**Impact:** rough birth-volume × error size. **Fix:** what a second pass would need.

| # | State | Item | Type | Impact | Fix needed |
|---|-------|------|------|--------|-----------|
| 1 | Georgia | ✅ **FIXED (2026-09):** Fulton (Atlanta) + Cobb/Clayton/Cherokee/Forsyth dropped from the Western-GA Central set → now resolve statewide EST (Etc/GMT+5) like DeKalb; 43 true-Central counties unchanged; regression tests added; geojson normalised to compact geometry. **Mountain-tier residual RESOLVED (2026-09, crop-verified PDF 104, no change needed):** all 7 boundary counties (Union/Fannin/Gilmer/Lumpkin/Dawson/Pickens/Bartow) cite Shanks **GA #8** (97–100% majority), which the time-tables crop shows is **Central-no-DST from 1919 → switches to Eastern on 1941-03-21**. So they were *genuinely* Central pre-1941 — the earlier "may be over-included" worry is refuted; dropping them would reintroduce a 1 h error. The shipped feat[40] (`Etc/GMT+6`, window 1919-10-26..1941-03-21) already covers them and its window ends exactly at the switch; feat[264/265] (`Etc/GMT+5`) carry post-1941 EST. Verified every indexed city in all 7 counties resolves CST pre-1941 (no CDT summer leak — the per-county `America/Chicago` features are correctly shadowed by feat[40]) and EST in 1946. 3 regression tests added (`test_ga_mountain_*`). **Note:** the per-county `America/Chicago` GA features (feat[43/46/59/71/75/77/79]) are dead code (always shadowed) — harmless but removable in a future cleanup. | bug (fixed) + residual (resolved) | done | — (verified correct; no geometry change) |
| 2 | Florida | Pre-1919 peninsula was **Central** (switched to Eastern 1919-01-01); IANA models it Eastern back to 1883 → pre-1919 peninsula births read 1 h fast. | transition | low (pre-1919 volume) | Not a flat fix — peninsula ran CWT (−05) in 1918 before the switch; needs a transition zone, not flat Etc/GMT+6. |
| 3 | Florida | Minority post-war local DST: FL #2/#3/#4 (Central) had CDT in scattered 1931/1941/1946–65 summers; FL #6 (Eastern) EDT 1946. Dominant no-DST override over-corrects those county-summers. | minority | low | Per-county summer carve-outs or synthetic zones; low value. |
| 4 | Alabama | Minority-table city DST the statewide AL_1 doesn't model: AL #2 (summers 1958–60) and AL #4 (1935, 1940) — likely Birmingham/Mobile one-off local DST. Under-corrected (reads CST). | minority | low | Per-city-year carve-outs; not worth it standalone. |
| 5 | Idaho (N) | Panhandle within-county **1961-resumer cities** (ID #1/#4/#7/#10/#12): flat override forced PST 1961–63 though these towns resumed summer DST in 1961. **✅ FIXED (2026-09) for all 5 resumer tables:** the flat Etc/GMT+8 panhandle override is now a TOWN-LEVEL split — the ID #1/#4/#7/#10/#12 towns (incl. **Coeur d'Alene** and **Lewiston**, two of the largest north cities) carry a per-town `shanks: ID_1` transition zic (PST→PDT summers 1961–63); the rest keep the flat PST unchanged. Crop-verified that each resumer table resumes on the identical standard 1961 dates, so one zic represents all five in-window. This is the per-town **transition**-zone override the atlas OCR was built for. The 1965-summer tail (window ends 1964-04-26) is still uncorrected (one summer, low value). | minority | resolved (1965 tail: very low) | 1965 tail: widen the window + add the 1965 PDT transition if a birth needs it. |
| 6 | Idaho (N) | **Pre-war local DST 1931–1941** (ID #3/#6/#8/#9/#10/#11) + ID #7 (1952) / ID #9 (1950) single postwar DST summers — America/LA omits (opposite sign); flat PST override untouched/under-corrects. | minority | low | Synthetic Pacific-with-early-DST zones per town; low value. |
| 7 | Idaho (S) | **Postwar MDT** America/Boise omits: ID #13/#17 (1961–63), ID #15 (1964–65). Not a county majority anywhere, so nothing shipped. | minority | low | Synthetic Mountain-with-DST zones if a county majority ever emerges. |
| 8 | Idaho (S) | **1919 daylight sliver**: Mountain-from-1919 override starts 1919-10-26, so Jan–Oct 1919 (the switch + that summer's national daylight, MWT) is left to IANA. | sliver | very low | Transition zone for 1919; fraction of one year. |
| 9 | Illinois | **LARGELY RESOLVED (2026-09) — flat downstate override refined into a per-town CST cohort nest** (`build_il.rb`). Crop-verified the IL time tables (tt PDF 128-130 → `research/index/IL/tt_verified.md`): the dominant IL#4 (997t) = pure CST → US#2 1959-07-01, IL#55 (236t) → CDT 1955, IL#7 (120t) → CDT 1946, IL#1/#2/#3 = continuous CDT (=IANA). Replaced the two flat Etc/GMT+6 features with a pre-war + postwar pair of `split` features carrying per-town date-ranged CST `sched`: 21 verified CST tables get their exact spans (defer once they adopt DST), IL#1/#2/#3 defer, and **unclassified downstate towns DEFAULT to the IL#4 pattern (CST 1920-1941 + 1946-1958) = the old flat behavior, so nothing regresses**. Verified vs the old flat: 672/5920 sampled cells changed, **every one CST→defer** (the town-by-town over-correction removed), 0 regressions. 1 test. | minority (residual) | low | Remaining: ~29% of downstate towns on small/unread tables default to the IL#4 CST pattern (correct for the CST majority per state law; a handful of unread early-DST tables stay over-corrected). Crop-verify the <15-town tables from `research/index/IL/tt_reocr/` to tighten. |
| 10 | Illinois | **RESOLVED by #9's cohort nest** — LaSalle's DST towns (on IL#1/#2/#3 continuous-CDT or early-adopter tables) now defer in their DST years via the per-town `sched` instead of being folded into a flat CST vote. | minority | — | — (superseded by #9). |
| 11 | Indiana | **The whole state, pre-1970.** Central portions observed summer DST, Eastern portions did not, and counties switched Central↔Eastern at poorly-documented dates 1940s–60s. Shanks tables adopt CDT at scattered years (1920/1925/1929/1930/1946/1955…) and diverge from IANA's 8 `America/Indiana/*` sub-zones (which model CDT summers Indianapolis 1948–60, Vincennes 1954–64) **in both directions**. Only a statewide `warn` shipped — no offsets asserted. | **transition / large** | **high** (whole state, ~50 yrs) but **hard** | **CROP-VERIFIED (2026-09) — the warn is the CORRECT final disposition, not a punt.** Rendered + read the IN time tables (tt PDF 150-155). The atlas intro is explicit: *"This state has a very complex time zone picture… Even newspaper reports present contradictory information. Time changes for smaller towns are not complete."* Decisive finding: **Indiana's summer clock is −5 statewide regardless of framing** — the intro's own rule is "the CST portions observe daylight (CDT = −5) while the EST portions do not (EST = −5)," so CDT and EST are *equivalent in effect* every summer (like the Chicago note in IL). The read tables confirm it: most IN tables run Central-with-CDT-summers, then switch to Eastern-no-DST ~1964 — but −5 either way in summer. So **IANA's −5 is already correct for the high-value summer-birth case**; the only residual divergences are winter-Central (−6) pockets and contested boundary counties, which are exactly the "contradictory / not documented" cases. There is **no dominant table** (top IN#101 = 7%, fragmented across 269 tables) to anchor a safe correction (unlike Michigan's clean 47% MI#1). Asserting Shanks' fragmentary per-town data over IANA's reasonable best-guesses would risk being wrong for negligible gain. **Disposition: keep the statewide warn (defer + verify note) — confirmed correct by crop-verification.** (If ever revisited: only the tiny documented exceptions — SE counties near Cincinnati/Louisville on EDT −4 summers, already flagged — could carry a bounded correction.) |

| 14 | Michigan | **DOMINANT CORRECTION SHIPPED (2026-09); contested tail still warns.** The LP kept CENTRAL time and switched to Eastern piecemeal, but IANA America/Detroit (flat EST −5, no transitions 1915→1942) applies Detroit's 1915 switch to the whole peninsula, so Central LP towns read 1 h fast. Crop-verified (tt PDF 263-267 → `research/index/MI/tt_verified.md`): **MI#1 (961t, 47%) = CST → EST 1931-04-26** and **MI#25 (185t) = CST until WWII → EST 1945**. Shipped a town-level `split` (`build_mi.rb`) giving MI#1 towns Etc/GMT+6 for [1919-10-26, 1931-04-26] and MI#25 towns for [1919-10-26, 1942-02-09] — **884 towns (56%) corrected**; every other table has no schedule and keeps the honest ambiguity `warn` (defer). Replaced the 67-polygon pure-warn with this one feature (same geometry, so nothing outside the western/central LP changes). WWI daylight (CWT −5 = IANA) and postwar Eastern/DST need no correction. 2 tests. | minority (tail) | medium (dominant done; tail is per-table DST/contested) | Remaining: 259 eastern-LP/Thumb MI#1 towns (Central-until-1931 dubious there) defer; the DST-bearing LP tables (MI#30/#35/#40 CDT, MI#57/#88/#92…) + the WWII CWT blip are undocumented/contradictory. Crop-verify the next tier from the renders to extend; leave genuinely-contested tables on the warn. |
| 15 | Minnesota | **MN #3 Twin Cities metro** (~46 towns in Hennepin/Ramsey/Anoka/Dakota/Washington): observed CDT in isolated summers **1932 & 1946** (then continuously from 1957), whereas the statewide flat Etc/GMT+6 override (correct for MN #1 = 95%, no-DST until 1957) asserts CST. Over-corrected for exactly those two metro summers. | minority | low–medium (populous metro, but only 2 summers) | Higher-value than IA #12 (Twin Cities population). Town-level split or a metro exclusion guard over the MN #3 towns for [1932-04-24..1932-09-06] and [1946-04-28..1946-09-29], deferring to IANA (which has CDT). County-level guard would over-defer the rural MN #1 towns in those counties, so it needs the town-level `split`. |
| 16 | Mississippi | **MS #2 Jackson metro** (~17 towns, Hinds county + fringe): observed CDT in a single summer **1935**, whereas the statewide flat Etc/GMT+6 override (correct for MS #1 = 99%, pure CST no-DST to 1967) asserts CST. Over-corrected for that one metro summer only. | minority | very low (1 summer) | Metro exclusion guard / town-level split over the MS #2 towns for [1935-04-28..1935-09-29], deferring to IANA. Tiny; opportunistic. |
| 17 | Montana | **Pre-war no-DST minority under-corrected.** The town-level MST split tags only the crop-verified no-DST tables MT #1/#9 (90%). MT #2 and MT #10 adopted DST only in 1946, so they too were MST no-DST PRE-war (1919–1942) — but they defer in the pre-war window (safe under-correction, ~30 towns get IANA MDT where MST was right). Also MT #3 had isolated peacetime DST 1935/1936. | minority | low | Pre-war: extend the no-DST tag to MT #2/#10 (crop-verify their pre-war rows first). Postwar they correctly defer (they had MDT). |
| 18 | Nevada | **Eastern-Mountain war-time offset.** The eastern-NV Mountain split applies flat Etc/GMT+7 (MST, −7) across its windows, but during WWII (1942-02-09..1945-09-30) those towns observed MWT (−6). So a war-years eastern-NV birth reads MST (−7) where it was MWT (−6). (IANA gives PWT −7 there too, also not −6.) | war-years sliver | very low (sparse desert, 3.5 yrs) | Add a war-time carve-out (−6) if a birth needs it; also NV #2's 1967 tail + the "undocumented" boundary edge towns. |
| 19 | New Hampshire | **Two tiny no-DST tables + minority pre-adoption tail.** The 2-window NH split tags NH #1 (rural, EST to 1937) in W2; the small NO-DST tables NH #10/#14 (~5 towns) may have kept EST past 1937 but defer from 1931 (under-corrected). Also the urban minority tables (NH #2/#3/#5…) adopted DST at staggered years 1931-1936 — their pre-adoption EST is captured only by W1 (to 1931), so [1931, their-year) is deferred (safe). | minority | low | Extend to a full Maine-style adoption-year cohort nest (ocr years are reliable — NH tables are self-contained), and crop-verify NH #10/#14. |
| 20 | New Jersey | **Small-tail cohort coalescing.** The 3-window NJ nest (boundaries 1921/1931/1937) handles the big rural tables NJ #2/#17/#12 exactly, but the small tail (#3/#7→1922, #4→1928, #5→1930, #14→1932, #8/#15→1933, #16→1934) drops EST at the nearest boundary ≤ its adoption — so e.g. NJ #4 (1928) gets EST only to 1921, deferring [1921,1928] to IANA (EDT). Under-correction only (~200 tail towns lose a few years of EST). | minority | low | Add the intermediate windows (1922/1928/1930/1932/1933/1934) for a full cohort nest — ocr US#-adoption years are reliable (NJ tables self-contained). |
| 12 | Iowa | **IA #12 urban exception** (a single town/county): observed DST in 1941 (pre-war) and again from 1957, whereas the statewide CST overrides assert CST. Over-corrected for summer 1941 (pre-war override) and handled by the 1954+ warn thereafter. Also the 1954–1967 town-by-town adoption is a `warn`, not corrected. | minority | low | Per-county carve-out for the IA #12 town(s); low volume. |

| 13 | Louisiana | **Plaquemines Parish** is an intra-parish split (Shanks ~65% zone-1 CST / 35% zone-2): the lower Mississippi delta observed CDT in summer 1946 like New Orleans, but the parish majority is CST so it stays in the statewide CST override (not in the NOLA 1946 guard). Lower-delta 1946-summer births are over-corrected to CST. | minority | very low (sparse delta) | Sub-parish guard for lower Plaquemines, summer 1946; tiny population. |

| 21 | Ohio | **Table 1 excluded (OCR contamination).** The single digit "1" is the atlas OCR's dominant misparse target: the index's ~289 "table 1" rows are mostly DST-city towns (Cleveland/Cincinnati/Toledo/Youngstown) whose real 2-digit table (#26/#88/#31/#84) was misread as "1" (with a bled county#). Classifying t1 over-corrected those metros to no-DST via the nearest-town snap, so `build_oh.rb` DEFERS t1. Genuine Shanks OH#1 western towns (crop-verified CST→1922→EST no-DST) are thus under-corrected (defer to IANA). | minority (OCR) | low–medium (metros protected; a few genuine western towns lose coverage) | Re-OCR the western city pages to recover the real OH#1 town→table# (2-digit), or embed the genuine OH#1 towns by name from the crop; then add t1 (switch 1922-09-01) to `build_oh.rb`. |
| 22 | Ohio | **Western county-seats under-corrected.** Small western cities that have their own (unclassified/DST) table — e.g. Greenville (Darke, OH#110), Wapakoneta (Auglaize), Marietta (Washington) — snap via nearest-town to a defer table, so they read IANA EST/EDT instead of the western CST(pre-1927)/EST-no-DST their rural counties kept. Safe under-correction (never over-corrects). | minority | low | Crop-verify each western county-seat's table (many are just unclassified, not DST) and add the no-DST ones to `build_oh.rb`. |
| 23 | Ohio | **Rural Butler/Hamilton pre-1927 reads CDT, not CST-no-DST.** The pre-existing Cincinnati metro override (feat[109]/[110], Butler+Hamilton → America/Chicago until 1927-01-20) is lower array index, so it shadows the town split for those two counties. America/Chicago applies CDT summers 1920-26 that the rural (OH#34) towns did not observe → 1 h fast those summers. | minority | very low (2 counties, rural, ≤1927) | Restrict feat[109]/[110] geometry to the Cincinnati metro (not whole counties), or convert to a town split so rural Butler/Hamilton fall through to the OH cohort nest (Etc/GMT+6 pre-1927). |
| 24 | Ohio | **DST-city tables + unclassified long tail defer.** The cohort nest classifies the crop-verified no-DST tables (~78% of indexed towns: OH#4/5/21/27/32/33/34/35/67). The big-city DST tables (OH#2/26/31/39/43/84/88/91/107) and the unclassified tail (tables <15 towns, plus t9/t37/t42/t46/t72/t96 which showed peacetime DST) default to defer → IANA. Where a tail table was actually no-DST, those summers read IANA EDT (1 h fast); where it was a DST city, defer is correct. | minority | low–medium (city populations, but IANA models their DST) | Crop-verify the next tier of tables (t20/t95/t105/t106/t93 etc.) from `oh_work/tt*_cols.txt` and add the no-DST ones; the DST cities correctly defer. |

| 25 | Oklahoma | **Panhandle was Mountain (MST) until 1921-03-08.** Crop-verified OK#4 (24 towns: Cimarron/#13 + Texas/#70 entirely, Beaver/#4 partly = 3 of 11 towns) = MST 1883→1921-03-08, then CST → US#1 1967. The statewide flat Etc/GMT+6 override asserts CST for 1919-10-26..1921-03-08 (1 h fast). IANA America/Chicago also has the panhandle CST then, so the override is no worse than IANA — but the *correct* value is MST. | sliver | very low (sparsest OK corner, ~1.4 yr) | Add a flat Etc/GMT+7 override over Cimarron (40025) + Texas (40139) for 1919-10-26..1921-03-08, **inserted at a lower array index than the flat-CST feat (so it wins the overlap)**; Beaver's 3 MST towns need a town split (mixed county). |
| 26 | Oklahoma | **NE-corner OK#2/#3 adopted CDT before 1967.** OK#2 (4 towns, Nowata/Washington area) took CDT from 1962; OK#3 (3 towns, Ottawa county, near MO/KS) took CDT earlier. The flat CST override over-corrects those town-summers to CST. | minority | very low (7 towns) | Town-level carve-out for OK#2/#3 following the neighbouring KS/MO metro DST; tiny. |

| 27 | Oregon | **Edge-year DST summers deferred.** The flat Etc/GMT+8 override covers only 1953-1960 (the decade ALL Oregon tables kept PST). At the edges the tables disagree: rural OR#2 kept PST 1952 & 1961-1962 (IANA PDT) — under-corrected; urban Portland OR#12 had PST 1948-1949 too but also PDT 1948-1952 & 1961. Summers 1948-1952 and 1961-1962 defer to IANA (safe under-correction where OR was PST; correct where OR had DST). | minority | low–medium (edge summers, but the core decade is corrected) | Per-table cohort nest (like NY/Ohio): give each town Etc/GMT+8 only in the summers its own table kept PST. Needs crop-verified DST-year sets for all ~17 OR tables. |
| 28 | Oregon | **Malheur panhandle (OR#1, MST).** Malheur County (FIPS 41045) = MST no-DST 1883-1962, then MDT summers 1963-1974, US#1 1975. IANA America/Boise (which Malheur uses) is MST no-DST through the 1960s, so the base zone matches and Malheur is excluded from the flat PST override. Residual: MDT summers 1963-1974 (Shanks) vs IANA MST → 1 h slow under IANA for those summers. | sliver | very low (29 sparse towns, 1963-74) | Add an Etc/GMT+6 (MDT) override over Malheur for the 1963-1974 summers if a birth needs it. |

| 29 | Pennsylvania | **RESOLVED (2026-09) — full cohort nest shipped, all tables ≥20 towns classified.** Replaced the pre-war-only PA#1+#6 core with a full NY-style per-table cohort nest (`build_pa.rb`): **65 crop-verified tables** carry their exact EST-summer sets, emitted as a **pre-war + postwar pair of `split` features whose every town holds its own date-ranged `sched`** (the exact spans its table was EST, from America/New_York's DST-transition instants). **5799/6730 towns (86%) corrected pre-war, 2350 postwar** — including the postwar holdouts PA#6 (EST→1956), #66 (→1957), #98 (→1954), #7 (→1953), #59 (→1951), #51 (→1948), and every rural table ≥20 towns. Each read visually from `research/index/PA/tt_reocr/` (persisted) → `research/index/PA/tt_verified.md`. **Crop-verification corrected two stale claims:** PA#6 adopts US#2 in **1956** (not 1965), and PA#9 = **Philadelphia adopts DST 1921** (the OCR-draft `early=[]` was the row-drop the memory warned about). 3 tests. **Remaining defer (correct, not a gap):** the DST cities (Philadelphia PA#9, Pittsburgh PA#114, Erie PA#107, + full-DST PA#74/#84/#88/#95/#120) genuinely had daylight → IANA is right. Only ~130 towns on tables <20 towns are unread (safe under-correction). | resolved | — | (Optional) read the <20-town tables from `research/index/PA/tt_reocr/`; re-extract with `--max-table=125` to recover tables 116-123. |

| 30 | South Dakota | **Far-west Mountain (SD#3) vs IANA-Denver spurious MDT.** SD#3 (181 sparse western towns) = pure MST no-DST 1883-1967; it defers to IANA America/Denver via the tier-0 far-west warn (feat[4]). IANA Denver = MST for 1921-1964 (correct) but applies spurious MDT in summers **1920, 1965, 1966** → those SD#3 summers read 1 h fast. Also SD#4 (14 transition towns near the Missouri River) defer and may be CST no-DST (under-corrected). No systematic CST-bleed onto Mountain (unlike NE/ND — only 1 far-west coord artifact). | sliver + minority | very low (sparse west, 3 summers) | For the 1920/1965/1966 slivers: a narrow Etc/GMT+7 override over the western counties (like the CO Denver-1920/21 fix) — but must supersede the tier-0 feat[4] warn, so it's really a full CST/MST town split (build_nd.rb template): SD#1→GMT+6, SD#3→GMT+7, classify SD#4. Low priority given the sparse population. |

| 31 | Utah | **Far-west Utah / Nevada-border Pacific cluster (UT#2).** Crop-verified: UT#2 (~33 towns) = PST no-DST until 1969 (PDT summers 1966-68, then MDT 1969) — the far-west border communities (Ibapah/Gandy/Garrison/Trout Creek, lon ≤ -113.9) aligned with Nevada (Pacific), while IANA models all Utah as America/Denver (Mountain) → 1 h slow under IANA for ~46 years. NOT shipped: the indexed UT#2 town set is contaminated (~12 of 33 sit at lon -112, central Utah = almost certainly misassigned to UT#2), so a Pacific override would over-correct them. The shipped flat MST gives the true far-west towns Etc/GMT+7 = IANA (no worse, just not the correct Pacific -8). | minority (Pacific) | very low (sparse Nevada-border towns) | Re-verify which UT#2 towns are genuinely lon ≤ -113.9 (far-west), then a town-level split → Etc/GMT+8 for [1919-10-26..~1966] over just those; defer the messy 1966-69 PDT/MDT transition. |

| 32 | Vermont | **Early-DST minority + late-table tail deferred.** The town split asserts only the crop-verified dominant VT#1 (74%, EST no-DST->1955). The SE early-adopter tables (Brattleboro VT#13 ~1935, VT#15 ~1936, VT#2 ~1938, VT#3 ~1939, VT#4 ~1940) defer -- their own pre-adoption EST-no-DST years (1919->their adoption) read IANA EDT (under-corrected). Also VT#6/#14 (OCR suggests ~1955 like VT#1) defer, not crop-verified. | minority | low (small state, minority tables) | Full cohort nest (like NH/NJ): per-table adoption-year windows for the minority tables (crop-verify each from research/index/VT/tt_ocr_cols.txt). |

| 33 | Washington | **Early-DST minority tables deferred.** The town split asserts only the crop-verified dominant WA#1 (74%, PST no-DST->1961). The minority tables that adopted DST earlier/scattered (WA#8 PDT 1948-1951, WA#4 1949/1951/1956, + the smaller tables) defer -- their PST-no-DST years in the gaps read IANA PDT (under-corrected). | minority | low (small minority, sparse) | Per-table PST-year windows for the minority tables (crop-verify from research/index/WA/tt_ocr_cols.txt). |

| 34 | Wisconsin | **Dominant WI#1 under-corrected in the two fringe-warn windows.** The shipped treatment warns 1919-1923 (early-1920s city DST experiments in the city tables) and 1955-1967 (staggered adoption), deferring to IANA there. But WI#1 (the dominant rural table) had NO 1919-1923 experiments (CST straight from 1919) and held CST no-DST until 1957 -- so its 1919-1923 and 1955-1956 summers read IANA CDT (under-corrected). Safe (never over-corrects); the warns are conservative because the city/early-adopter tables disagree in those windows. | minority | low-medium (dominant table, ~7 fringe summers) | Town-level split: assert WI#1 -> Etc/GMT+6 across 1919-1923 and 1955-1956 too (crop-verify WI#2-6 experiment/adoption years from research/index/WI/tt_ocr_cols.txt), leaving the city tables to warn. |

| 35 | Arizona | **Far-west + southern Arizona Pacific tables (AZ#2/#3).** AZ#2 (25t) + AZ#3 (44t) = far-west Colorado-River strip (all indexed lon <= -113.3: Mohave/La Paz/Yuma) on Pacific time (PST -8) while IANA models AZ as America/Phoenix (Mountain -7). **NOW FLAGGED (not silent): a note-bearing warn over Mohave+La Paz+Yuma (build_az.rb) surfaces the possible Pacific time** so these births are not silently served as Mountain. No offset asserted -- Shanks flags AZ#3 as "estimated from incomplete information" and the town set has garbled county#s. Phoenix (Maricopa) is east, unaffected. | sliver (uncertain, flagged) | very low (sparse SW/far-west, estimated) | If a specific far-west/southern-AZ birth needs it: crop-verify the AZ#2/#3 town set + switch dates, then a town split -> Etc/GMT+8; but Shanks flags the data as incomplete. |

## Also parked (from earlier states, lower detail)

- **Connecticut** — CT table-3 cities in the override counties under-corrected for summer
  1920 only (majority vote). minority / very low.
- **Delaware** — New Castle (Wilmington metro) ~29% rural no-DST towns accepted as a
  minority under the IANA-ok classification. minority / low.
- **Colorado** — Denver-metro straddle counties (Adams/Douglas/Jefferson + Broomfield)
  shipped as `warn`, not corrected. minority / low (already flagged to users).
- **Maine** — the 7-window cohort nest (2026-09) coalesces adoption boundaries to 6 years
  (1931/1932/1934/1936/1938/1940), so tables adopting in the skipped years (1933: #8/#36/#37;
  1935: #26/#32; 1937: #24/#34; 1941: #2/#22) lose ~1 year of EST at the tail (defer to IANA
  instead of EST). Under-correction only, never over — safe. ME #28 (3 towns, unread) and
  the ME #36/#37 stray-1933-summer tables are treated as defer/adopt-1933 conservatively.
  minority / low. Refine with per-year windows if a specific birth surfaces the need.

## ⚠ SYSTEMIC OCR BUG (2026-09): multi-page TIME TABLES mis-parsed as cities

`build_atlas_index.rb` assumed **exactly one TIME-TABLES page per state** and derived each
state's city-listing range as `tt+1 .. next_state_tt-1`. **Any state whose time tables span
>1 page therefore had its extra tt pages parsed as bogus "cities"** (garbled names, real
coords, table# from the tt rows) AND its high-numbered tables never captured. Detected by
counting transition rows (`02:00` / `Before 11/18`) in the top of each `tt+off` page
(scratch `ny_work/ttspan.sh`). **Affected states (tt span in pages):**

| State | tt span | Status | Action |
|---|---|---|---|
| NY | 8 | **DONE** | re-OCR'd (tt 352-359, cities 360-386, `--max-table=226`) → clean index 4817 towns; 11-window cohort nest shipped. Residual: long-tail tables <15 towns unclassified (see NY tail below). |
| **ME** | 2 | **FIXED (2026-09)** | tables **ME#39-#49 are REAL** (crop-verified pg 230); the old `--max-table=38` guard had dropped ~230 towns. Re-OCR'd (cities 230-238, `--max-table=49`) → index rebuilt 959→**1188 towns**; extended ADOPT to tables 1-49 + added a 2nd postwar window (captures ME#47's 1946-48 EST). Big recoveries: ME#44 (81t, adopt 1931), #45 (64t, 1946), #47 (50t, 1949). 3 tests. Residual: messy blip tables ME#39/40/41/42/46/49 (≤10t each) use first-DST-year adopt → safe under-correction of their post-blip EST. |
| KY | 3 | done (seed, targeted #69/#71) | index incomplete; KY shipped only Louisville + Campbell/Kenton by hand — revisit if a KY birth needs a rural table. |
| IN | 11 | done* (statewide warn, deferred) | index junk already noted (#11); the dedicated pass must rebuild the index with tt 150-160 excluded from city range. |
| IL | 5 | done (county-map, not index) | index junk; downstate override was county-map-based so shipped features OK, but the town-level residual work (#9) needs a clean index (tt 128-132 are tt). |
| MI | 5 | probed/deferred (#14) | index junk; the dedicated pass must use tt 263-267. |
| OH | 5 | **DONE (2026-09)** | tt 409-413 (5-page span); **page 413 is BOTH the last tt page AND the first city page (A-Au towns)**. Re-OCR'd (tt 409-413, cities 413bottom-431, `--max-table=118`) → clean index 2883 towns. Shipped a two-zone CST/EST town-level split cohort nest (`build_oh.rb`) replacing the buggy flat-EST override + postwar warn. Residuals: rows #21-24 below. |
| PA | 5 | **DONE (2026-09)** | tt 448-452 (5-page span); **page 452 is BOTH last tt page AND first city page (A-cities)**. Re-OCR'd (cities 452bottom-493, `--max-table=115`) → clean index 6730 towns. Shipped the full cohort nest (33 crop-verified tables, pre-war + postwar holdouts; `build_pa.rb`) as 2 per-town date-ranged-`sched` split features. Low-town tail deferred (row #29). |
| MO | 2 | **DONE** | tt 300-301; index already clean (tt rows do not parse as cities). Replaced postwar warn with a 5-window CST cohort nest (dominant MO#3=86% CST to 1966). |
| TN | 2 | **DONE (2026-09)** | tt 510-511 (2-page span; p511 is pure tt, no city-bottom). Rebuilt the corrupt index (cities 512-530, `--max-table=40`) → 2366 towns. VERIFY-CONFIRMED the elaborate pre-existing two-zone treatment (feat[8-36] flat CST/EST + per-county East-TN "Central until 1946-1960" overrides feat[84-108] + NE Tri-Cities warn feat[111-115]). Crop-verified anchors: TN#3 pure CST (West/Middle), TN#1 pure EST (Eastern). No new features; 6 tests (commit 2d58c8c). |
| VT | 2 | pending | tt 560-561. |
| WA | 2 | pending | tt 592-593. |
| WV | 2 | pending | tt 603-604. |

**Fix for pending states:** on first touch, VERIFY where tt ends / cities begin by scanning
page headers (don't trust that tt is one page); rebuild the index with the correct
`--cities=<first>-<last>` and `extract_cities --max-table=<real max>`. The 40 single-tt-page
states (span=1) are UNAFFECTED — their indices are clean.

### NY long-tail tables (unclassified)

The NY cohort nest classifies every table with **≥15 towns** (crop-verified EST-year sets:
NY#1-36 + #41/#42/#45/#48/#75/#86/#105/#151/#153/#186/#211/#226), covering ~85% of the
4817 indexed towns (~2650 correctable). The remaining ~180 tables (each <15 towns, ~15% of
towns / ~730) are **not yet classified → they default to no zone = defer to IANA** (those
EST summers read 1 h fast). Safe under-correction, never wrong. To extend: crop-verify the
next tier of tables from `research/index/NY/timetables.json` (tt renders in scratch
`ny_work/reocr/tt352-359`) and add their EST-year sets to `TABLE_EST` in
`research/builders/build_ny.rb` (the window mechanism already handles arbitrary EST
intervals). Also a handful of the classified messy tables lose 1-2 summers at window seams
(e.g. NY#20 misses summer 1950, #15 misses 1940) from boundary coalescing — safe
under-correction; refine with finer windows if a specific birth needs it.

## How to work this backlog

Sort by Impact. Item 1 (Georgia) is fully resolved — the Fulton metro bug was fixed and
the N/NE-mountain boundary counties were crop-verified as genuinely Central pre-1941 (no
change needed). Item 11 (Indiana) is the largest and highest-impact *residual* but also the
hardest — a dedicated multi-day pass in its own right (and Shanks flags the data as
contradictory, so it may only partly resolve). Item 9 (Illinois town-by-town) is the next
largest residual but is tractable because the IL city→county→table map already exists in a
session scratchpad. Everything else is low-volume minority/sliver work — batch it, or
address opportunistically when a specific birth record surfaces the need.

## Engine / data-size optimization (cohort nests)

The cohort-nest states originally embedded **one snap-anchor copy of every town per window**.
The engine now supports a **per-town date-ranged schedule** (`resolve_split` reads a town's
`sched: [[from, until, zone], …]` and picks the segment covering the birth date), which
collapses a state's N window-features into a small fixed number of `split` features whose
every town appears ONCE with its own EST spans. Resolution is **bit-for-bit identical** to the
windowed form (same snap, same zone, same defer — verified across 5296 PA (town,date) cases),
but it removes the N× town duplication.

- **✅ PA (2026-09):** converted 23 windows → 2 schedule features (pre-war + postwar). PA's
  geojson footprint dropped from ~9.5 MB to ~0.65 MB; `name` kept.
- **NY still uses the 11-window form** (`build_ny.rb`) — ~10 MB of the file. Converting it to
  the same `sched` shape (one/two features) is the obvious next size win, same engine, no
  accuracy change. Do this before adding another NY-scale windowed nest.
- A cheaper-but-LOSSY alternative (dropping the per-town `name`, which feeds only the note's
  "(Resolved via …, X)" suffix) is **not needed** now that the schedule form keeps names AND
  is smaller.

## Index-informed status (2026-09, branch `feature/deferred-backfills`)

The full-atlas index (`research/index/<ST>/`, git-ignored) + `tools/analyze_split.rb`
(geographic-separability test) now make most of this a query, not a re-render. Findings:

**Geographic-split backfills** (candidates that were `warn`/IANA-ok):
- **DE New Castle** — separability **0.93 / 20 km** override(no-DST rural south) vs
  defer(DST Wilmington). Currently shipped IANA-ok; a `split` would correctly give the
  rural-south towns Etc/GMT+5. Real (if modest) fix. *Next: crop-verify pg 85–89, clean
  the town names, emit via `map_counties --split-emit`, add a test.*
- **DE Kent** — **0.84 / 13 km**, borderline geographic → a `split` resolves the warn.
- **DE Sussex** — **not a split**: no defer group (uniformly no-DST) → already correct as a
  flat override. Remove from split candidates.
- **CO Jefferson / LA c38** — spatially separable BUT must first confirm the two tables
  differ in DST/offset (separability alone ≠ a meaningful split). Pending table-semantics.

**Georgia Fulton bug** (item 1) — *index helps but needs a clean GA county map first.*
The Central set is feat[40] (48-poly `Etc/GMT+6`) + feat[41–88] (per-county
`America/Chicago`); Fulton (13121) is wrongly inside → Atlanta reads Central 1919–41.
Blocker found: the GA index's **159-county legend did not OCR into names**, and the
"GA #11–15 = Central" table labels don't line up with the index's table numbers, so the
Central FIPS set can't yet be re-derived by county#. **Refined approach:** identify the
true Central counties GEOGRAPHICALLY (western tier, town-lon ≲ −84.8, sharing the Central
table) from the index town coords, map to FIPS by point-in-county (coords → plotly county
polygons), then re-emit feat[40] + the per-county Central features COMPACT minus Fulton +
any Eastern-voting metro (DeKalb/Cobb/Clayton/Cherokee), and assert Atlanta→Eastern
1919–41 in a test. Careful geometry work — do it deliberately, not rushed (rushing is what
produced the original over-inclusion).

**Illinois (item 9/10)** and **Indiana (item 11)** — the prerequisite city→county→table
maps are now permanent in the index (IL 3018 cities/121 counties; IN 2040/98), so both are
unblocked from the OCR side; each still needs its own authoring pass (IL per-county DST
windows; IN sub-zone reconciliation + synthetic zic).
