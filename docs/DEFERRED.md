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
| 1 | Georgia | **Fulton (Atlanta) wrongly in Western-GA Central set** (features #40 + #80): Atlanta resolves Central 1919–41 outside the 1937–40 guard — a 1–2 h error. Likely other Atlanta-metro/N-GA counties over-included too. | **bug** | **high** (Atlanta = large metro, 20+ yrs) | Geometry surgery: re-emit #40/#80 compact with Fulton (+ Cobb/Clayton/Cherokee?) removed, or re-adjudicate the boundary. |
| 2 | Florida | Pre-1919 peninsula was **Central** (switched to Eastern 1919-01-01); IANA models it Eastern back to 1883 → pre-1919 peninsula births read 1 h fast. | transition | low (pre-1919 volume) | Not a flat fix — peninsula ran CWT (−05) in 1918 before the switch; needs a transition zone, not flat Etc/GMT+6. |
| 3 | Florida | Minority post-war local DST: FL #2/#3/#4 (Central) had CDT in scattered 1931/1941/1946–65 summers; FL #6 (Eastern) EDT 1946. Dominant no-DST override over-corrects those county-summers. | minority | low | Per-county summer carve-outs or synthetic zones; low value. |
| 4 | Alabama | Minority-table city DST the statewide AL_1 doesn't model: AL #2 (summers 1958–60) and AL #4 (1935, 1940) — likely Birmingham/Mobile one-off local DST. Under-corrected (reads CST). | minority | low | Per-city-year carve-outs; not worth it standalone. |
| 5 | Idaho (N) | Panhandle **1965 summer** + within-county **1961-resumer cities** (ID #1/#4/#7/#10/#12): override ends 1964-04-26 following dominant ID #2, so 1965 is uncorrected and 1961-resumer towns are over-corrected to PST 1961–63. | minority | low | Per-county window split; town-by-town, low volume. |
| 6 | Idaho (N) | **Pre-war local DST 1931–1941** (ID #3/#6/#8/#9/#10/#11) + ID #7 (1952) / ID #9 (1950) single postwar DST summers — America/LA omits (opposite sign); flat PST override untouched/under-corrects. | minority | low | Synthetic Pacific-with-early-DST zones per town; low value. |
| 7 | Idaho (S) | **Postwar MDT** America/Boise omits: ID #13/#17 (1961–63), ID #15 (1964–65). Not a county majority anywhere, so nothing shipped. | minority | low | Synthetic Mountain-with-DST zones if a county majority ever emerges. |
| 8 | Idaho (S) | **1919 daylight sliver**: Mountain-from-1919 override starts 1919-10-26, so Jan–Oct 1919 (the switch + that summer's national daylight, MWT) is left to IANA. | sliver | very low | Transition zone for 1919; fraction of one year. |
| 9 | Illinois | **Town-by-town DST adoption downstate**: larger towns had 1930s CDT (IL #14 etc.); some adopted DST 1946 (IL #7) or across the 1950s (IL #8/#50/#55…) before the 1959 law change. Flat CST override (majority IL #4) over-corrects those town-summers. | minority | medium (many towns, decades) | Per-county/per-table windows from the county map; sizeable but tractable with the existing IL map. |
| 10 | Illinois | **LaSalle County** (Ottawa, ~15% Chicago-DST cities) folded into the downstate CST override by majority vote; its DST towns are over-corrected. | minority | low | Split LaSalle into a warn or town-level treatment. |

## Also parked (from earlier states, lower detail)

- **Connecticut** — CT table-3 cities in the override counties under-corrected for summer
  1920 only (majority vote). minority / very low.
- **Delaware** — New Castle (Wilmington metro) ~29% rural no-DST towns accepted as a
  minority under the IANA-ok classification. minority / low.
- **Colorado** — Denver-metro straddle counties (Adams/Douglas/Jefferson + Broomfield)
  shipped as `warn`, not corrected. minority / low (already flagged to users).

## How to work this backlog

Sort by Impact. Item 1 (Georgia Fulton bug) is the only **bug** and the highest-value
single fix. Item 9 (Illinois town-by-town) is the largest *residual* but is tractable
because the IL city→county→table map already exists in a session scratchpad. Everything
else is low-volume minority/sliver work — batch it, or address opportunistically when a
specific birth record surfaces the need.
