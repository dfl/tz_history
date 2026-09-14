# International Atlas — coverage ledger

One row per country worked against the Shanks *International Atlas*. See
`docs/INTL_EXTRACTION.md` for the plan. Printed page = PDF − 24.

**Disposition** — `override` (a Shanks/flat correction ships) · `iana-sufficient`
(default IANA already correct pre-1970, no-op) · `defer` (IANA better-sourced; flag
only) · `pending` (not yet worked). **Resolution** — `polygon` (country-wide) ·
`split` (province / nearest-city) · `warn` · `—`.

| Country | Printed p. | PDF p. | Tables | Disposition | Resolution | IANA cross-check | Status |
|---------|-----------:|-------:|-------:|-------------|------------|------------------|--------|
| Netherlands | 277 | 301 | 9 (NL#1 anchor) | override | polygon | `backzone` Europe/Amsterdam — 575/575 mid-months 1892–1940 to the second | ✅ done (NL#1; #2–9 regional-variant refinements deferred) |
| Iceland | 195 | 219 | 1 | override | polygon | `backzone` Atlantic/Reykjavik (Almanak-sourced) — **742/744** mid-months 1908–1969 | ✅ done (IS_1) |
| Ireland | 217 | 241 | 1 | iana-sufficient | — | `Europe/Dublin` is a FULL zone in the default `europe` (DMT −0:25:21 → 1916), already correct | ✅ verified no-op (defer) |
| Luxembourg | 256 | 280 | 1 | override | polygon | `backzone` Europe/Luxembourg — **790/792** mid-months 1904–1969 | ✅ done (LU_1) |
| Norway | 286 | 310 | 1 | override | polygon | `backzone` Europe/Oslo — **900/900** mid-months 1895–1969 | ✅ done (NO_1) |
| Sweden | 377 | 401 | 1 | override | polygon | `backzone` Europe/Stockholm — **1092/1092** mid-months 1879–1949 | ✅ done (SE_1) |

**Phase-1 sub-hour European mean-time cluster** (worklist order): Iceland ✅ · Ireland
❌ no-op · Luxembourg ✅ · Norway ✅ · Sweden ✅. Page map in `research/intl/atlas_pages.tsv`.

**Coastline resolution (10m + Douglas–Peucker).** The builder sources Natural Earth
**10m** admin_0 (not 50m): the runtime does EXACT ray-cast point-in-polygon with no
tolerance, and the coarse 50m coastline drops Stockholm's Baltic archipelago (and other
coastal cities) *outside* the country polygon — a capital resolving to `nil` is
unacceptable. The 10m rings are ~8× heavier, so each ring is RDP-simplified at
`SIMPLIFY_EPS = 0.01°` (~1.1 km) — RDP fills bays inclusively and only trims convex
tips (where cities rarely sit); `research/intl/rdp_probe.rb` verifies no city
regressions/leaks across the tested capitals + majors. Intl geojson: 61 KB → 164 KB.
**Known limit:** exact PIP against *any* coastline still misses cities a few km offshore
of NE's line — e.g. Tromsø (3.8 km out, on Tromsøya) and Luleå (1.2 km, head of the
Gulf of Bothnia) resolve to `nil` (→ IANA default). A future outward-buffer / near-edge
tolerance pass would recover these; deferred (tiny far-north populations).

**Sweden notes.** Printed p.377 = PDF 401 packs Swaziland / Sweden (Sweden is the
middle entry). Sweden was the FIRST country with a national standard time (law 1878,
effective 1879-01-01): **Swedish Time +1:00:14** (Stockholm meridian less 12 min)
1879–1900, then **CET** from 1900, with summer time ONLY in 1916. Default Links
`Europe/Stockholm → Europe/Berlin`, so it is 1–2 h off in 1917–18 and 1940–49 (Germany
kept DST, neutral Sweden did not). **Two law-sourced deferrals** (backzone, Ivan Nilsson
2001, EXPLICITLY "superseding Shanks & Pottenger"): (1) the 1879–1900 offset — Shanks
prints +1:12 (full Stockholm meridian), the law gives +1:00:14; (2) the 1916 summer-time
start — Shanks prints 14/Apr (visual-verified Shanks error), the law puts it 14/May.
With both applied, SE_1 matches backzone 1092/1092. Window 1879 .. 1950. **Pre-1879 town
LMT deferred** (Phase-2 nearest-city, like Norway).

**Norway notes.** Printed p.286 packs Norfolk Island / Norway. Default Links `Europe/Oslo
→ Europe/Berlin`, but Norway's summer-time years (1916, 1940–45, 1959–65) differ from
Germany's, so the default is a full hour off in 1917–18, 1945–49 and 1959–65 (NO_1 matches
backzone Oslo 900/900). Window 1895 (uniform CET) .. 1966. **Pre-1895 is deferred**: Norway
had no national time then — the atlas geocodes each town's own LMT (Oslo +0:43, Ålesund
+0:24:36, Alta +1:32:48), a nearest-city job → Phase-2 backlog.

**Luxembourg notes.** Printed p.256 packs three entries (Liechtenstein / Luxembourg /
Macau); Luxembourg is the middle. Default IANA Links `Europe/Luxembourg → Europe/Brussels`
(WET), but Luxembourg ran **CET (+1)** 1904–1918 (Brussels was WET → an hour low), then
WET 1918–1940 (with its own summer-time dates, differing from Belgium's), then CET at the
1940 occupation (default agrees thereafter). Window 1904-06-01 .. 1940-05-14. The two
mid-month cross-check misses are Mar–Apr 1940, where backzone applies Belgium's spring
DST as a proxy while Shanks holds Luxembourg on WET until the May occupation switch
(a Shanks-primary retention). The marginal pre-1904 LMT (+0:24:36, ~24 min) is deferred.

**Ireland is NOT a Phase-1 target** (triage correction). The divergence tool never
listed `Europe/Dublin`; the hand-written queue conflated it with the divergent
`Europe/Belfast` (25:21). Default `Europe/Dublin` already carries Dublin Mean Time
(−0:25:21 LMT/DMT until 1916-10-01, then IST/GMT), so an ROI birth resolves correctly
without us. The real gap is **Northern Ireland** (`Europe/Belfast` → Link to London,
losing pre-1916 Irish time) — a UK sub-national split, deferred to **Phase 2**.

**Iceland notes.** Default IANA Links `Atlantic/Reykjavik → Africa/Abidjan` (GMT), so it
serves +0:00 across all of 1908–1968 — wrong by a full hour every winter (Iceland kept
−1:00, meridian 15W, with summer time raising the clock to GMT; −1:28 Reykjavík MST
before 1908; permanent GMT from 1968-04-07). Shanks p.195 is primary and visually
corroborates the base offset; three Shanks data-quality gaps were deferred to the
sourced Icelandic Almanak (via backzone): the **omitted 1939 & 1940 summer time** and
the **spurious July 1941 & 1942 fall-backs**. The two remaining mid-month cross-check
misses are Nov 1918/1919, where Shanks records the summer-end one day before the Almanak
(a Shanks-primary date, not an offset error).

## Phase-2 backlog (deferrals to pick up later)

Sub-national splits, giants, and refinements surfaced while working Phase 1. Each stays
here until worked, so "N countries done" never reads as "everything covered." (Master
divergence worklist: `research/intl/iana_divergence.tsv`, 108 zones / 94 countries.)

| Item | Kind | Why deferred | Surfaced by |
|------|------|--------------|-------------|
| Northern Ireland (`Europe/Belfast`, 25:21) | UK sub-national split | Default Links Belfast → London, losing pre-1916 Irish time; ROI (Dublin) already correct, so this is a within-UK boundary, not a country override | Ireland triage |
| Norway pre-1895 town LMT | nearest-city | Before uniform CET (1895) every Norwegian town kept its own LMT (Oslo +0:43, Ålesund +0:24:36, Alta +1:32:48…); the atlas geocodes them — a Phase-2 nearest-city split, not a polygon | Norway (NO_1) |
| Sweden pre-1879 town LMT | nearest-city | Before national Swedish Time (1879) every town kept its own LMT (the atlas geocodes each) — a Phase-2 nearest-city split, like Norway | Sweden (SE_1) |
| Coastal-fringe PIP misses | outward-buffer / near-edge tolerance | Exact ray-cast PIP against NE's 10m coastline still drops cities a few km offshore of the line (Tromsø 3.8 km, Luleå 1.2 km → `nil`/IANA); a small outward buffer or "within-ε-of-edge" runtime test would recover them | Sweden/Norway coastline |
| Netherlands tables #2–9 | regional-variant refinement | NL#1 (Amsterdam/whole-country) ships; the finer regional variants are lower-value refinements | NL pilot |

**Known Shanks errors (defer to IANA, do not ship):**
- **Netherlands, summer 1945.** Shanks TT#1 ends daylight time on **20 May 1945** (clocks
  → CET); the correct date is **16 September 1945** (the liberated Netherlands stayed on
  +2:00/CEST through the summer, in step with Germany, then kept CET permanently). IANA is
  right — its NL data is sourced from R.H. van Gent's *wettijd* study; Shanks cites nothing.
  `NL_1` is windowed to end at 1940-05-16, so the gem already defers to IANA for 1945 (correct).
  Classic "IANA has a sourced primary contradicting Shanks → defer" case.

---

## Phase 0 — IANA-divergence triage (worklist)

`tools/iana_divergence.rb` compiles the tz database two ways (default build vs the opt-in
`backzone`) and diffs every backzone zone's observed offset 1890–1969. Result:
**108 zones / 94 countries** where the DEFAULT IANA build is wrong pre-1970 (a Link/backzone
gap Shanks can fill). Full ranked table: `research/intl/iana_divergence.tsv` (regenerable).

By divergence magnitude: **67 whole-hour+ · 23 sub-hour (Amsterdam-class) · 18 LMT-residue (<20m)**.

**Priority queue — Phase 1 single-zone polygon-override fast wins** (real inhabited, single
dominant zone; grouped):
- **Sub-hour mean-time gaps** (highest interpretive value, Amsterdam-class): Netherlands ✅,
  Ireland/Dublin (Belfast 25m), Luxembourg, Iceland (71m), Stockholm/Sweden, Oslo/Norway.
- **Whole-hour West-Africa cluster** (WAT −1 or LMT vs GMT default): Senegal, Mali, Guinea,
  Sierra Leone, Gambia, Mauritania, Niger, Benin, Ghana, Togo, Burkina Faso, Côte d'Ivoire.
- **Caribbean cluster** (LMT/AST gaps vs GMT/EST default): Curaçao, Aruba, Bahamas, Antigua,
  St Kitts, Trinidad, St Vincent, St Lucia, Dominica, Grenada, Guadeloupe, Montserrat, both
  Virgin Islands, Cayman.
- **Central/East Africa** (LMT vs +1/+2 default): Congo (Kinshasa/Lubumbashi), Angola, Cameroon,
  Gabon, CAR, Tanzania, Uganda, Ethiopia, Eritrea, Somalia, Madagascar, Réunion, Seychelles.
- **Asia/Pacific**: Laos, Cambodia, Brunei, Malaysia, Oman, Kuwait, Bahrain, Micronesia, Saipan.

**Skip as noise** (dateline artifacts / uninhabited / alias mislabels): Midway, Wake, Enderbury,
Kerguelen, Jan Mayen, Johnston, Christmas/Cocos (verify), and any <20m LMT-residue rows that
resolve to already-standardized capitals (low birth-record impact).

_Country → atlas page for a worked country: locate on first touch (header scan, as for NL) or
from the back-of-book index (PDF ~448–455)._
