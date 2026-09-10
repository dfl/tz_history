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
| 9 | Illinois | **Town-by-town DST adoption downstate**: larger towns had 1930s CDT (IL #14 etc.); some adopted DST 1946 (IL #7) or across the 1950s (IL #8/#50/#55…) before the 1959 law change. Flat CST override (majority IL #4) over-corrects those town-summers. **Index probe (2026-09) — the OCR is CLEAN; the fragmentation is REAL:** 96% of IL table citations land on tables cited ≥5× (65 real tables), coords 100% in-bbox, county# accurate. LaSalle's towns cite heavily-used real tables (t4 cited **997×** statewide, t55 236×, t6 65×, t26 71×); its top table is only 13% because IL DST adoption was **genuinely town-by-town**, each town on its own real table. So there is NO clean COUNTY signal — the residual is irreducibly town-level, not an OCR artifact. | minority | medium (many towns, decades) | Author-side, not OCR: accept the majority-vote minority (current), or embed per-town `split` features (tool exists, but the plan discourages per-town points at scale). Either way each real table must be labeled CST-to-1959 vs early-DST (crop the IL time tables). Accepted-minority for now. |
| 10 | Illinois | **LaSalle County** (Ottawa, ~15% Chicago-DST cities) folded into the downstate CST override by majority vote; its DST towns are over-corrected. **Index probe:** LaSalle's votes are fully fragmented (top table 13%, no majority) — no clean split or exclusion; converting to a `warn` would only drop coverage the majority still wants. Leave as accepted minority. | minority | low | Leave (accepted minority); revisit only if a specific Ottawa-area birth surfaces the need. |
| 11 | Indiana | **The whole state, pre-1970.** Central portions observed summer DST, Eastern portions did not, and counties switched Central↔Eastern at poorly-documented dates 1940s–60s. Shanks tables adopt CDT at scattered years (1920/1925/1929/1930/1946/1955…) and diverge from IANA's 8 `America/Indiana/*` sub-zones (which model CDT summers Indianapolis 1948–60, Vincennes 1954–64) **in both directions**. Only a statewide `warn` shipped — no offsets asserted. | **transition / large** | **high** (whole state, ~50 yrs) but **hard** | A dedicated pass: build the IN city→county→table map (`tools/map_counties.rb` over PDF 150–~163), map each county to its IANA sub-zone, and author synthetic zic zones for the EST-year-round and early-CDT patterns where they beat IANA. This is a multi-day research project of its own; Shanks himself flags the data as contradictory, so some counties may stay `warn`. **Index probe (2026-09):** the prerequisite map now exists and is CLEAN — IN index 2040 cities, 91/92 counties, **86% of table citations on real (≥5×) tables**, 60% of counties with a clear ≥60% majority; the time-tables draft shows usable per-table DST patterns (IN_2/3/5/8/11 differ). (A stray #939 singleton is a rare outlier, not the norm.) So OCR is NOT the blocker. The real work is unchanged and large: reconcile each county → its IANA `America/Indiana/*` sub-zone and AUTHOR synthetic zic for the ~79 real tables' EST-year-round / early-CDT patterns. A dedicated multi-session pass — not safe to rush (wrong synthetic zones for a state Shanks calls "contradictory" are worse than the honest statewide `warn`), but it is now an AUTHORING task on clean data, not an OCR fight. |

| 14 | Michigan | **The whole state, two-zone + contested pre-1931.** Crop-verified (PDF 263/printed 251): the dominant table **MI #1 (961 index towns, 47%) is CENTRAL (CST) from 1885, switching to Eastern only on 1931-04-26**, then EST no-DST until 1967 — while **IANA America/Detroit is Eastern (EST) from 1915**. So ~half the state's documented towns diverge by 1 h (Central, not Eastern) for **1915–1931**. Shanks' own intro flags it: "Not all zone shifts... during the 20's... portions of Michigan...". The western UP is genuinely Central (matches America/Menominee — no divergence). The index cites **100+ tables** (dominant only 47%, long town-by-town tail) with varied Central→Eastern switch dates + the 1946–1966 EST-no-DST era (which IANA America/Detroit already models). | **transition / large** | **high** (whole state, zone-level) but **hard** | Dedicated multi-session pass, exactly like Indiana (#11): build the MI city→county→table majority map (index exists: 2060 cities, but table# noisy — a few 900s — so run `extract_cities --max-table=~111`), cluster counties by Central-until-Y vs Eastern, author synthetic transition zics (CST→EST at the county's switch year, EST-no-DST to 1967) where they beat America/Detroit, and leave the western-UP Central counties to America/Menominee. NOT safe to rush (contradictory two-zone state; wrong synthetic zones worse than deferring to IANA). Honest disposition for now: **no override shipped — defers to IANA America/Detroit / America/Menominee.** |
| 15 | Minnesota | **MN #3 Twin Cities metro** (~46 towns in Hennepin/Ramsey/Anoka/Dakota/Washington): observed CDT in isolated summers **1932 & 1946** (then continuously from 1957), whereas the statewide flat Etc/GMT+6 override (correct for MN #1 = 95%, no-DST until 1957) asserts CST. Over-corrected for exactly those two metro summers. | minority | low–medium (populous metro, but only 2 summers) | Higher-value than IA #12 (Twin Cities population). Town-level split or a metro exclusion guard over the MN #3 towns for [1932-04-24..1932-09-06] and [1946-04-28..1946-09-29], deferring to IANA (which has CDT). County-level guard would over-defer the rural MN #1 towns in those counties, so it needs the town-level `split`. |
| 16 | Mississippi | **MS #2 Jackson metro** (~17 towns, Hinds county + fringe): observed CDT in a single summer **1935**, whereas the statewide flat Etc/GMT+6 override (correct for MS #1 = 99%, pure CST no-DST to 1967) asserts CST. Over-corrected for that one metro summer only. | minority | very low (1 summer) | Metro exclusion guard / town-level split over the MS #2 towns for [1935-04-28..1935-09-29], deferring to IANA. Tiny; opportunistic. |
| 12 | Iowa | **IA #12 urban exception** (a single town/county): observed DST in 1941 (pre-war) and again from 1957, whereas the statewide CST overrides assert CST. Over-corrected for summer 1941 (pre-war override) and handled by the 1954+ warn thereafter. Also the 1954–1967 town-by-town adoption is a `warn`, not corrected. | minority | low | Per-county carve-out for the IA #12 town(s); low volume. |

| 13 | Louisiana | **Plaquemines Parish** is an intra-parish split (Shanks ~65% zone-1 CST / 35% zone-2): the lower Mississippi delta observed CDT in summer 1946 like New Orleans, but the parish majority is CST so it stays in the statewide CST override (not in the NOLA 1946 guard). Lower-delta 1946-summer births are over-corrected to CST. | minority | very low (sparse delta) | Sub-parish guard for lower Plaquemines, summer 1946; tiny population. |

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

## How to work this backlog

Sort by Impact. Item 1 (Georgia) is fully resolved — the Fulton metro bug was fixed and
the N/NE-mountain boundary counties were crop-verified as genuinely Central pre-1941 (no
change needed). Item 11 (Indiana) is the largest and highest-impact *residual* but also the
hardest — a dedicated multi-day pass in its own right (and Shanks flags the data as
contradictory, so it may only partly resolve). Item 9 (Illinois town-by-town) is the next
largest residual but is tractable because the IL city→county→table map already exists in a
session scratchpad. Everything else is low-volume minority/sliver work — batch it, or
address opportunistically when a specific birth record surfaces the need.

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
