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
| Denmark | 121 | 145 | 1 | override | polygon | `backzone` Europe/Copenhagen — **960/960** mid-months 1890–1969 | ✅ done (DK_1) |
| Netherlands Antilles (Aruba + Curaçao) | 280 | 304 | 3 (TT#3 anchor) | override | polygon | `backzone` America/Curaçao **& America/Aruba** — **695/696** mid-months (1912–1969; sole miss = Jan-1912 island LMT, out of window) | ✅ done (CW_1); SSS + Bonaire → Phase 2 |
| Equatorial Guinea | 137 | 161 | 1 | override | polygon | `backzone` Africa/Malabo — **696/696** mid-months 1912–1969 | ✅ done (GQ_1); GMT 1912→WAT 15 Dec 1963; default links to Lagos (WAT from 1919) |
| Niger (Niamey / western div) | 283 | 307 | 3 (TT#2 anchor) | override | polygon | `backzone` Africa/Niamey — **696/696** mid-months 1912–1969 | ✅ done (NE_1); TT#2 −01→GMT→WAT; east(+1)/central(GMT→1960) divs → Phase 2 |
| Tanzania (mainland / Dar es Salaam) | 385 | 409 | 2 (TT#2 anchor) | override | polygon | `backzone` Africa/Dar_es_Salaam — **468/468** mid-months 1931–1969 | ✅ done (TZ_1); TT#2 EAT/+2:45; Zanzibar TT#1 (+2:30 1931–40) → Phase 2 |
| Senegal | 314 | 338 | 1 | override | polygon | `backzone` Africa/Dakar — **696/696** mid-months 1912–1969 | ✅ done (SN_1); −1:00 1912 → GMT 1 Jun 1941; default links to Abidjan (GMT) |
| Guinea | 191 | 215 | 1 | override | polygon | `backzone` Africa/Conakry — **696/696** mid-months 1912–1969 | ✅ done (GN_1); GMT 1912 → −1:00 26 Feb 1934 → GMT 1 Jan 1960; default links to Abidjan |
| Mauritania | 262 | 286 | 1 | override | polygon | `backzone` Africa/Nouakchott — **696/696** mid-months 1912–1969 | ✅ done (MR_1); GMT 1912 → −1:00 26 Feb 1934 → GMT 28 Nov 1960; default links to Abidjan |
| Mali (Bamako / southern div) | 260 | 284 | 2 (TT#2 anchor) | override | polygon | `backzone` Africa/Bamako — **696/696** mid-months 1912–1969 | ✅ done (ML_1); TT#2 GMT→−1:00(1934)→GMT(20 Jun 1960); northern TT#1 (GMT throughout = default) needs no fix; IANA models all Mali as Bamako |
| The Gambia | 165 | 189 | 1 | override | polygon | `backzone` Africa/Banjul — **696/696** mid-months 1912–1969 | ✅ done (GM_1); BMT −1:06:36 1912 → −1:00 (1 Apr 1933) → GMT (1 Feb 1942), IANA ordinance dates (Shanks 1935/1964 = errors, deferred) |
| Sierra Leone | 314 | 338 | 1 | defer | — | `backzone` Africa/Freetown — Shanks DST (save 0:40, Jun–Oct) contradicted by almanac-sourced IANA rules (save 0:20) + WWII GMT-1941 vs Shanks 1957 | ⏳ deferred (Phase 2); see backlog |
| Benin | 27 | 51 | 1 | override | polygon | `backzone` Africa/Porto-Novo — **696/696** mid-months 1912–1969 | ✅ done (BJ_1); GMT 1912 → WAT (+1:00) 26 Feb 1934; default links **east** to Lagos (WAT from 1919) → 1h fast 1919–1934 |
| Ghana | 186 | 210 | 1 | defer | — | `backzone` Africa/Accra (P Chan ordinance-sourced `Rule Ghana`) — sub-hour, conflicts with Shanks | ⏳ deferred (Phase 2); see backlog |
| Côte d'Ivoire | 238 | 262 | 1 | iana-sufficient | — | `Africa/Abidjan` is a FULL real zone in the default build (LMT −0:16:08 → GMT 1912), and is itself the GMT anchor the whole cluster links to | ✅ verified no-op |
| Togo | 388 | 412 | 1 | iana-sufficient | — | `backzone` Africa/Lome (LMT +0:04:52 → GMT **1893**) — no whole-hour gap; only ≤21 min pre-1912 LMT residue vs the Abidjan link | ✅ verified no-op; pre-1912 sub-hour LMT → Phase 2 |
| Burkina Faso (Upper Volta) | — | — | 1 | iana-sufficient | — | `backzone` Africa/Ouagadougou (LMT −0:06:04 → GMT 1912) = the default from 1912; only 10 min pre-1912 LMT residue | ✅ verified no-op; pre-1912 sub-hour LMT → Phase 2 |
| Anguilla | 5 | 29 | 1 | override | polygon | `backzone` America/Anguilla — **960/960** mid-months 1890–1969 | ✅ done (AI_1); LMT −4:12:16 → AST −4:00 (2 Mar 1912) |
| Antigua & Barbuda | 5 | 29 | 1 | override | polygon | `backzone` America/Antigua — **960/960** mid-months 1890–1969 | ✅ done (AG_1); **EST −5:00 (1912) → AST −4:00 (1 Jan 1951)** — the cluster outlier |
| Dominica | 123 | 147 | 1 | override | polygon | `backzone` America/Dominica — **960/960** mid-months 1890–1969 | ✅ done (DM_1); LMT −4:05:36 (Roseau) → AST −4:00 (1 Jul 1911) |
| Grenada | 189 | 213 | 1 | override | polygon | `backzone` America/Grenada — **960/960** mid-months 1890–1969 | ✅ done (GD_1); LMT −4:07:00 (St George's) → AST −4:00 (1 Jul 1911) |
| Guadeloupe | 189 | 213 | 1 | override | polygon (bbox) | `backzone` America/Guadeloupe — **960/960** mid-months 1890–1969 | ✅ done (GP_1); LMT −4:06:08 (Pointe-à-Pitre) → AST −4:00 (8 Jun 1911); geometry carved from France by bbox; St-Barth/St-Martin → Phase 2 |
| Montserrat | 273 | 297 | 1 | override | polygon | `backzone` America/Montserrat — **960/960** mid-months 1890–1969 | ✅ done (MS_1); LMT −4:08:52 (Plymouth) → AST −4:00 (1 Jul 1911) |
| St Kitts & Nevis | 308 | 332 | 1 | override | polygon | `backzone` America/St_Kitts — **960/960** mid-months 1890–1969 | ✅ done (KN_1); LMT −4:10:52 (Basseterre) → AST −4:00 (2 Mar 1912) |
| St Lucia | 308 | 332 | 1 | override | polygon | `backzone` America/St_Lucia — **960/960** mid-months 1890–1969 | ✅ done (LC_1); Castries MT −4:04:00 → AST −4:00 (1 Jan 1912); the 1890 step is the same offset |
| St Vincent | 309 | 333 | 1 | override | polygon | `backzone` America/St_Vincent — **960/960** mid-months 1890–1969 | ✅ done (VC_1); Kingstown MT −4:04:56 → AST −4:00 (1 Jan 1912) |
| Trinidad & Tobago | 389 | 413 | 1 | override | polygon | `backzone` America/Port_of_Spain — **960/960** mid-months 1890–1969 | ✅ done (TT_1); LMT −4:06:04 (Port of Spain) → AST −4:00 (2 Mar 1912); both divisions share the table |
| Virgin Islands (US) | 400 | 424 | 1 | override | polygon | `backzone` America/St_Thomas — **960/960** mid-months 1890–1969 | ✅ done (VI_1); LMT −4:19:44 (Charlotte Amalie / St Thomas) → AST −4:00 (1 Jul 1911) |
| Virgin Islands (British) | 400 | 424 | 1 | override | polygon | `backzone` America/Tortola — **960/960** mid-months 1890–1969 | ✅ done (VG_1); LMT −4:18:28 (Road Town / Tortola) → AST −4:00 (1 Jul 1911) |
| Cameroon | 44 | 68 | 1 | override | polygon | `backzone` Africa/Douala — **960/960** mid-months 1890–1969 | ✅ done (CM_1); LMT → WAT (+1:00) 1/Jan/1912; default links to Lagos (WAT only 1 Sep 1919) → 30–47 min slow 1912–1919 |
| Central African Republic | 77 | 101 | 1 | override | polygon | `backzone` Africa/Bangui — **960/960** mid-months 1890–1969 | ✅ done (CF_1); LMT → WAT (+1:00) 1/Jan/1912; header UBANGI-SHARI; default links to Lagos |
| Congo (Brazzaville) | 116 | 140 | 1 | override | polygon | `backzone` Africa/Brazzaville — **960/960** mid-months 1890–1969 | ✅ done (CG_1); LMT → WAT (+1:00) 1/Jan/1912; default links to Lagos |
| Gabon | 165 | 189 | 1 | override | polygon | `backzone` Africa/Libreville — **960/960** mid-months 1890–1969 | ✅ done (GA_1); LMT → WAT (+1:00) 1/Jan/1912; default links to Lagos; shares p.189 with Gambia |
| Angola | 3 | 27 | 1 | override | polygon | `backzone` Africa/Luanda — **953/960** mid-months 1890–1969 | ✅ done (AO_1); LMT → +0:52 Luanda MT (1892) → WAT (+1:00) 26/May/1911; default links to Lagos; 7 misses = Jun–Dec 1911 sub-hour sliver (Shanks 26/May vs backzone 31/Dec) |
| Chad | 78 | 102 | 1 | iana-sufficient | — | `Africa/Ndjamena` is a FULL real zone (LMT +1:00:12 → WAT 1912) in the default build | ✅ verified no-op; only pre-1912 town LMT → Phase 2 |
| Zaire (Congo-Kinshasa) | 404 | 428 | 3 | defer | — | two-zone: TT#1 west +1:00 from 1897; TT#2 SE +1→+2 (25 Apr 1920 = Africa/Lubumbashi); TT#3 NE +1→+2 (14 Jun 1935) — IANA has only 2 zones (Kinshasa +1, Lubumbashi +2) | ⏳ deferred; needs a west/east division split (like NE two-division) |
| Ethiopia | 138 | 162 | 3 (TT#3 Addis) | override | polygon | `backzone` Africa/Addis_Ababa — **1200/1200** mid-months 1870–1969 | ✅ done (ET_1); ADMT +2:35:20 (38E50) → EAT 5 May 1936; default links to Nairobi (≤30 min off 1928–1942) |
| Eritrea | 138 | 162 | 1 (TT#1 Asmara) | override | polygon | `backzone` Africa/Asmara — **1200/1200** mid-months 1870–1969 | ✅ done (ER_1); AMT +2:35:32 → ADMT +2:35:20 (1890) → EAT 1936; part of Ethiopia in the 1985 atlas; default links to Nairobi |
| Somalia (+ Somaliland) | 315 | 339 | 1 | override | polygon | `backzone` Africa/Mogadishu — **1200/1200** mid-months 1870–1969 | ✅ done (SO_1); EAT 1893 → +2:30 (1931) → EAT (1957); SO_1 also covers the separate NE "Somaliland" polygon; default links to Nairobi |
| Djibouti | 123 | 147 | 1 | override | polygon | `backzone` Africa/Djibouti — **1200/1200** mid-months 1870–1969 | ✅ done (DJ_1); LMT → EAT (+3:00) 1 Jul 1911; default links to Nairobi (≤30 min slow 1911–1942) |
| Uganda | 395 | 419 | 1 | override | polygon | `backzone` Africa/Kampala — **1200/1200** mid-months 1870–1969 | ✅ done (UG_1); EAT (1928) → +2:30 (1930) → +2:45 (1948) → EAT (1957); default links to Nairobi |
| Madagascar | 257 | 281 | 1 | override | polygon | `backzone` Indian/Antananarivo — **1200/1200** mid-months 1870–1969 | ✅ done (MG_1); EAT from 1911 + a single summer DST (+4:00) 27 Feb–30 May 1954; default links to Nairobi (no DST) |
| Comoros | 115 | 139 | 1 | override | polygon | `backzone` Indian/Comoro — **1200/1200** mid-months 1870–1969 | ✅ done (KM_1); LMT (Moroni) → EAT 1 Jul 1911; default links to Nairobi |
| Mayotte | 115 | 139 | 1 | override | polygon (bbox) | `backzone` Indian/Mayotte — **1200/1200** mid-months 1870–1969 | ✅ done (YT_1); same Comoros-archipelago table (Mamoudzou LMT); geometry carved from France by bbox; default links to Nairobi |
| Réunion | 306 | 330 | 1 | override | polygon (bbox) | `backzone` Indian/Reunion — **1200/1200** mid-months 1870–1969 | ✅ done (RE_1); +4:00 from 1 Jun 1911; default links to **Dubai** (+4 only from 1920) → ~19 min slow 1911–1920; carved from France by bbox |
| Seychelles | 314 | 338 | 1 | override | polygon | `backzone` Indian/Mahe — **1200/1200** mid-months 1870–1969 | ✅ done (SC_1); +4:00; shipped IANA ordinance date 1 Jan 1907 (Shanks prints 1 Jun 1906 → deferred); default links to **Dubai** |
| Kenya | 250 | 274 | — | iana-sufficient | — | `Africa/Nairobi` is a FULL real zone and the cluster's link ANCHOR | ✅ verified no-op |

**Phase-1 sub-hour European mean-time cluster** (worklist order): Iceland ✅ · Ireland
❌ no-op · Luxembourg ✅ · Norway ✅ · Sweden ✅ · Denmark ✅. Page map in
`research/intl/atlas_pages.tsv`.

**Coastline resolution (10m + Douglas–Peucker + near-edge tolerance).** The builder
sources Natural Earth **10m** admin_0 (not 50m): the runtime does ray-cast
point-in-polygon, and the coarse 50m coastline drops Stockholm's Baltic archipelago
*outside* the country polygon. The 10m rings are ~8× heavier, so each ring is
RDP-simplified at `SIMPLIFY_EPS = 0.01°` (~1.1 km) — RDP fills bays inclusively and only
trims convex tips (where cities rarely sit); `research/intl/rdp_probe.rb` verifies no
regressions. Intl geojson: 61 KB → ~180 KB. But 10m alone is *not* enough — **Copenhagen
falls 1.24 km outside even the 10m coast** (a genuine sea-gap; a capital resolving to
`nil` is unacceptable). So `lib/tz_history/lookup.rb` adds an **`INTL_COAST_TOL` ≈ 2.8 km
near-edge tolerance** for the international overrides ONLY: a point strictly inside *or*
within tol of the outer ring counts as in-country. Open sea separates these countries, so
this is safe; it recovers Copenhagen, Stockholm, Luleå and Tromsø alike. The US county
corpus tiles continuously (shared borders between different-zone counties), so it keeps
`tol = 0` — an exact test, unchanged. **Only cost:** a ~2.8 km rural strip can leak across
a *land* border to a neighbour that itself defers to IANA (e.g. Padborg on Denmark's short
Jutland border with Germany); Flensburg (13 km) and farther cities defer correctly.

**Denmark notes.** Printed p.121 = PDF 145 (the page carries the tail of Czechoslovakia's
city listings above, then **DANMARK / DÄNEMARK**). Denmark took a national standard on
1890-01-01 — **Copenhagen Mean Time +0:50:20** (atlas header "Begin Standard 12E35") —
then **CET** ("15E00") from 1894-01-01. Summer time in 1916 (14 May–30 Sep), a continuous
occupation CEST 1940-05-15 → 1942-11-02, then annual Danish DST 1943–1948, then none until
the 1980 EU regime. Default Links `Europe/Copenhagen → Europe/Berlin`, so it is off in the
sub-hour CMT era (1890–1894), 1917–18, 1940 and 1945–**1949** (Germany kept DST that last
summer, Denmark did not). No Shanks-vs-backzone conflict — DK_1 matches backzone Copenhagen
**960/960**. Window 1890 .. 1950. NE maps Greenland and the Faroes as their own features,
so the country polygon is mainland + isles (incl. Bornholm). **Pre-1890 town LMT deferred**
(Phase-2 nearest-city, like Norway/Sweden).

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

**Netherlands Antilles notes** (first non-European / first Western-hemisphere override,
and the first *multi-table* country worked as a partial Phase-1 win). Printed p.280 = PDF
304 packs Netherlands / **NETHERLANDS ANTILLES** / New Caledonia. The atlas splits the
Antilles into **5 divisions × 3 time tables**, read off the city listing (`Name div#
table# LAT LON LMT`): **TT#1** `Begin Standard 60W00` (−4:00) → the northern SSS islands
(Sint Maarten div 5, part of Saba); **TT#2** `68W17` (−4:33) → Bonaire (div 2); **TT#3**
`67W30` (−4:30) → **Aruba (div 1) and Curaçao (div 3)**, then `60W00` (−4:00) from
1/Jan/1965. Aruba and Curaçao share the identical *standard* history, so **one CW_1 table
serves both polygons**; only their pre-1912 island LMT differs (Curaçao −4:35:44
Willemstad, Aruba −4:40:24), deferred with the LMT era. The DEFAULT IANA build **Links
both `America/Aruba` and `America/Curacao` → `America/Puerto_Rico`** (`backward`), which
observed −4:00 (AST) from 1899 and **−3:00 Atlantic War Time 1942–1945** — so the default
is 30 min fast across the whole 1912–1965 −0430 era and a full **90 min** off in 1942–1945;
the real detail lives only in `backzone`. Window 1912-02-12 .. 1965-01-01. **Deferred to
Phase 2:** the SSS islands (Shanks −4:00, which *diverges* from IANA's Curaçao-link) and
Bonaire (Shanks −4:33; IANA links `America/Kralendijk` to Curaçao = −4:30 anyway, so the
3-min sub-hour gap is immaterial). NE has Aruba and Curaçao as their own admin_0 features
(no `lat_min` filter needed); the `INTL_COAST_TOL` recovers their coastlines.

**Benin notes** (closes the whole-hour West-Africa cluster). Printed p.27 = PDF 51 packs
Belize / **BENIN** / Bermuda. Benin (Dahomey) is the one West-African colony whose IANA
default Links **east** to `Africa/Lagos` (not west to Abidjan): `Link Africa/Lagos
Africa/Porto-Novo` in `backward`. Lagos went to **WAT (+1:00) permanently on 1919-09-01**,
but Benin actually kept **GMT** until **26 Feb 1934** (then WAT) — so the default is a full
hour *fast* across 1919–1934. Shanks TT (visual-verified): `Before 1/Jan/1912 LMT / Begin
Standard 0w00 → GMT / Begin Standard 15E00 → 26/Feb/1934 −1:00` (Shanks's east-negative
convention; −1:00 = +1:00). Porto-Novo `2E37 −0:10:28` = +0:10:28 ahead, matching backzone
Africa/Porto-Novo (0:10:28) to the second. tzdb itself endorses the 1934 date — its comment
reads *"Benin: Whitman says they switched to 1:00 in 1946, not 1934; go with Shanks &
Pottenger."* So here IANA's best data *is* the Shanks datum we transcribe. `BJ_1` ≡ backzone
Porto-Novo **696/696** mid-months 1912–1969. Window 1912-01-01 .. 1934-02-26; pre-1912 town
LMT deferred (Phase 2).

**Ghana is DEFERRED** (Phase 2; the Sierra Leone class). Printed p.186 = PDF 210
(GHANA / GOLD COAST). Ghana is entirely **sub-hour** — no whole-hour gap ever, so a birth is
never mis-zoned by an hour vs the default (a plain-GMT link to Abidjan). Its divergences are
Ghana's famous +0:20 daylight time and a war-time +0:30 standard, and IANA carries these
from **P Chan's (2020) ordinance-sourced `Rule Ghana`** (with Gold Coast Ordinance citations)
— which *conflicts* with Shanks on multiple points: Shanks adopts GMT on **1/Jan/1918** (IANA
ordinance: **1915-11-02**); Shanks's +0:20 summer time runs ~**1936–1942** Sep→Dec, whereas
the ordinance rule runs **1919/1920–1941** (with the forward transition moved Sep→May in
1940–41); and Shanks has **neither** IANA's war-time +0:30 standard (1942-02-08 → 1946-01-06)
**nor** its 1950–1956 +0:30 daylight time. "IANA has a sourced primary contradicting Shanks →
defer." A faithful override must replicate the disputed sub-hour `Rule Ghana`, not a whole-hour
flat → Phase 2 (transcribe backzone, like Sierra Leone).

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

**Eastern Caribbean cluster** (twelve territories, one shared story — the Netherlands
Antilles pattern scaled up). Every Leeward/Windward island, Trinidad & Tobago, and both
Virgin Islands kept a sub-hour capital LMT until standardization (1911–1912), then adopted
**Atlantic Standard Time (AST, meridian 60W00 = −4:00)** with **no daylight or war time
ever** after. IANA's DEFAULT build **Links every one to `America/Puerto_Rico`** (`backward`),
which ran AST −4:00 from 1899 but then observed **−3:00 Atlantic War Time from 1942-05-03 to
1946** (US war rules) — so the default is a **full hour fast across 1942–1945** for the whole
cluster. Each island's Shanks Time Table matches its IANA `backzone` twin **960/960** mid-months
1890–1969 (the tables carry the capital LMT, so the match holds across the LMT era too); the
polygons are gated from each island's Shanks standardization date to 1970, and the
sub-hour pre-standardization town LMT is deferred (Phase-2 nearest-city). Notes per island:

- **Antigua & Barbuda (AG_1)** is the outlier: LMT → **EST −5:00 (75W00) 2 Mar 1912** →
  **AST −4:00 on 1 Jan 1951**. So it is a full hour *slow* vs the Puerto Rico link across the
  whole 1912–1951 EST era, and **two** hours off in the war years. Window ends 1951 (rejoins AST
  = default). Antigua & Anguilla share printed p.5 / PDF 29 (below Angola/Andorra).
- **St Lucia (LC_1)** and **St Vincent (VC_1)** print an extra 1890 "standard" step on a
  near-island meridian (61W00 / 61W14), but it is the **same offset** as their capital LMT
  (−4:04:00 Castries / −4:04:56 Kingstown) — IANA models it as CMT/KMT; no divergence. Both
  reach −4:00 on 1 Jan 1912. St Kitts & St Lucia share PDF 332 (below Rwanda); St Vincent is on
  PDF 333 (with Saint-Pierre & Miquelon).
- **Guadeloupe (GP_1)** has **no standalone Natural Earth admin_0 feature** — it is bundled
  into the "France" MultiPolygon (next to mainland France, Martinique and Réunion). `build_intl.rb`
  now supports a `bbox:` on a registry row that carves the department out of the parent geometry
  (Guadeloupe box `[-62.0, 15.7, -60.9, 16.7]` keeps Basse-Terre/Grande-Terre/Marie-Galante/Les
  Saintes/La Désirade, excludes Martinique at lat < 15 and St-Barth/St-Martin at lat > 17.8).
  Notably Guadeloupe observed **no** summer/war time here (unlike metropolitan France). Grenada &
  Guadeloupe share PDF 213 (below Greenland). St-Barthélemy & St-Martin (the Northern Islands,
  listed under Guadeloupe by Shanks) → Phase 2.
- **Trinidad & Tobago (TT_1)** prints two divisions (1 Tobago, 2 Trinidad) that share one time
  table; header is French (`TRINITÉ-ET-TOBAGO`), bottom of the Transkei page (PDF 413).
- **Virgin Islands** are one combined atlas entry (PDF 424) with two divisions — 1 British
  (Road Town/Tortola −4:18:28), 2 US (Charlotte Amalie/St Thomas −4:19:44) — shipped as two
  polygons (`VG_1`, `VI_1`) with the same 1 Jul 1911 AST adoption.

⭐ **Runbook confirmations:** the atlas is alphabetical by ENGLISH name (right-hand header),
printed = PDF − 24, and these small island entries sit at the **bottom** of a page topped by a
larger country (Denmark→Dominica, Greenland→Grenada, Mongolia→Montserrat, Rwanda→St Kitts,
Transkei→Trinidad). The back-of-book index page numbers are **unreliable** (multilingual
cross-refs, noisy OCR) — locate by alphabetical neighbour + header-band OCR instead. Bahamas is
**not** in this cluster (it is EST-based, `Link America/Nassau → America/Toronto`, a DST-rule
divergence, not the AST family) → separate follow-up.

## Phase-2 backlog (deferrals to pick up later)

Sub-national splits, giants, and refinements surfaced while working Phase 1. Each stays
here until worked, so "N countries done" never reads as "everything covered." (Master
divergence worklist: `research/intl/iana_divergence.tsv`, 108 zones / 94 countries.)

| Item | Kind | Why deferred | Surfaced by |
|------|------|--------------|-------------|
| Northern Ireland (`Europe/Belfast`, 25:21) | UK sub-national split | Default Links Belfast → London, losing pre-1916 Irish time; ROI (Dublin) already correct, so this is a within-UK boundary, not a country override | Ireland triage |
| Norway pre-1895 town LMT | nearest-city | Before uniform CET (1895) every Norwegian town kept its own LMT (Oslo +0:43, Ålesund +0:24:36, Alta +1:32:48…); the atlas geocodes them — a Phase-2 nearest-city split, not a polygon | Norway (NO_1) |
| Sweden pre-1879 town LMT | nearest-city | Before national Swedish Time (1879) every town kept its own LMT (the atlas geocodes each) — a Phase-2 nearest-city split, like Norway | Sweden (SE_1) |
| Denmark pre-1890 town LMT | nearest-city | Before national Copenhagen MT (1890) every Danish town kept its own LMT (Aalborg +0:39:44, Aarhus +0:40:52, …); the atlas geocodes them — a Phase-2 nearest-city split, like Norway/Sweden | Denmark (DK_1) |
| ~~Coastal-fringe PIP misses~~ | ✅ RESOLVED | The `INTL_COAST_TOL` ≈ 2.8 km near-edge tolerance (`lookup.rb`, intl-only) now recovers cities just offshore of NE's line (Copenhagen 1.24 km, Stockholm, Luleå, Tromsø). Residual: a ~2.8 km land-border strip can leak to an IANA-deferring neighbour (documented) | Denmark (DK_1) coastline |
| Netherlands tables #2–9 | regional-variant refinement | NL#1 (Amsterdam/whole-country) ships; the finer regional variants are lower-value refinements | NL pilot |
| Sierra Leone | country override | Shanks Time Table (p.314/PDF 338) has FMT −0:53 → −1:00 (1913) with a +40-min summer DST every year 1935–1942 (Jun→−0:20, Oct→−1:00) → GMT 1957. IANA `backzone` Africa/Freetown instead carries almanac-sourced `Rule SL` (save **0:20**, i.e. −0:40, in the dry season ~Sep–Mar, 1932–1939) and a WWII switch to plain −01 (1939) then **GMT from 6 Dec 1941** — explicitly noted as superseding Shanks. So Shanks conflicts on DST amount, season *and* the end date. The clean whole-hour −1:00 base (1913–1941) is real value vs the GMT default, but a faithful override must replicate the disputed sub-hour `SL` rules → a Phase-2 job (transcribe backzone, not Shanks). | W-Africa cluster (Sierra Leone) |
| Ghana | country override | Sub-hour throughout (+0:20 DST 1919/1920–1941, +0:30 war-time standard 1942–1946, +0:30 DST 1950–1956), all P Chan (2020) ordinance-sourced in `backzone` Africa/Accra — and Shanks conflicts (GMT adoption 1918 vs 1915-11-02; +0:20 window ~1936–1942 vs 1920–1941; Shanks lacks the +0:30 war-time & 1950s DST). No whole-hour gap, so never mis-zones a birth by an hour. A faithful override must transcribe the disputed sub-hour `Rule Ghana` (not Shanks) → Phase 2, like Sierra Leone. | W-Africa cluster (Ghana) |
| Togo / Burkina Faso / Côte d'Ivoire pre-1912 town LMT | nearest-city | All three are GMT from standardization = the default (Togo GMT from 1893, Burkina & the Abidjan anchor GMT from 1912), so there is **no whole-hour gap** and no override ships. The only divergence is sub-hour pre-1912 town LMT (Lomé +0:04:52, Ouagadougou −0:06:04 vs the Abidjan link's −0:16:08 — ≤21 min), a Phase-2 nearest-city job like Norway/Sweden/Denmark. | W-Africa cluster (iana-sufficient trio) |
| Mali northern division (TT#1) | admin_1 refinement | Shanks splits Mali into TT#2 (southern, Bamako = shipped ML_1) and TT#1 (northern/Saharan: Timbuktu, Gao, Kidal — GMT throughout). IANA models *all* Mali as Bamako, so the polygon override applies TT#2 everywhere (matching IANA); TT#1's GMT-throughout equals the default anyway, so nothing is lost. Recorded only for completeness. | Mali (ML_1) |
| Bahamas | country override | `Link America/Nassau → America/Toronto` (`backward`) — so the default applies US/Canada DST rules to Nassau pre-1976, but the Bahamas is EST (−5:00) with its **own** DST history. This is an EST + DST-rule divergence (up to 1 h during mismatched DST windows), a different animal from the Eastern-Caribbean AST family — needs its own Shanks Time Table (with the Bahamian DST rules) rather than a flat offset. | Eastern Caribbean cluster triage |
| St-Barthélemy & St-Martin (Northern Islands) | country override / nearest-city | Shanks lists Gustavia (St-Barth, −4:11:24) and Marigot (St-Martin, −4:12:24) under Guadeloupe, but they are geographically the Northern Islands (lat > 17.8, excluded from GP_1's bbox). IANA `backzone` links `America/Marigot` & `America/St_Barthelemy` → America/Port_of_Spain (−4:00). Their AST-adoption history needs its own read; low volume. | Guadeloupe (GP_1) bbox |
| Eastern Caribbean pre-standardization town LMT | nearest-city | Before AST adoption (1911–1912) each island kept its capital/town LMT (sub-hour, e.g. Roseau −4:05:36, Charlotte Amalie −4:19:44). The shipped polygons are gated from the standardization date; the LMT era defers to IANA (the Puerto Rico link, itself sub-hour off) → a Phase-2 nearest-city refinement, like Norway/Sweden/Denmark. | Eastern Caribbean cluster |

**Known Shanks errors (defer to IANA, do not ship):**
- **The Gambia transition dates.** Shanks prints BMT → −1:00 on **1/Jan/1935** and −1:00 →
  GMT on **1/Jan/1964**. IANA carries P Chan's (2020) ordinance-sourced dates instead:
  GMT−1 from **1933-04-01** (Interpretation Ordinance 1933, No. 10) and GMT from
  **1942-02-01** (Notice No. 5 of 1942, a war-time measure made permanent by the 1946
  Amendment Ordinance). `GM_1` ships the *sourced* dates (structure + BMT offset are
  Shanks-faithful, matching backzone 696/696); the window ends 1942-02-01 so 1942–1964 is
  correctly GMT (= default). "IANA has a sourced primary contradicting Shanks → defer."
- **Sierra Leone summer time.** Shanks's +40-min Jun–Oct DST (1935–1942) is contradicted by
  contemporaneous almanacs (see backzone `Rule SL`, save 0:20, ~Sep–Mar) — deferred entirely
  (see backlog above).
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
- **Whole-hour West-Africa cluster** ✅ COMPLETE (WAT −1 or LMT vs GMT default): Senegal ✅,
  Mali ✅, Guinea ✅, Gambia ✅, Mauritania ✅, Niger ✅, **Benin ✅** (the one that links
  *east* to Lagos, not Abidjan → 1h fast 1919–1934). Deferred: Sierra Leone ⏳ (sub-hour DST
  conflict), **Ghana ⏳** (sub-hour, ordinance-sourced `Rule Ghana` conflicts with Shanks).
  Verified iana-sufficient no-ops (Abidjan is the GMT anchor, no whole-hour gap): **Côte
  d'Ivoire** (Abidjan is itself a real zone), **Togo** (GMT from 1893), **Burkina Faso** (GMT
  from 1912) — their only divergence is sub-hour pre-1912 town LMT (→ Phase-2 nearest-city).
- **Caribbean cluster** (LMT/AST gaps vs GMT/EST default): Curaçao ✅, Aruba ✅ (CW_1), and the
  **Eastern Caribbean AST family** ✅ COMPLETE — Anguilla ✅, Antigua & Barbuda ✅ (EST outlier),
  Dominica ✅, Grenada ✅, Guadeloupe ✅ (bbox), Montserrat ✅, St Kitts ✅, St Lucia ✅,
  St Vincent ✅, Trinidad & Tobago ✅, US Virgin Is. ✅, British Virgin Is. ✅ — all default-Linked
  to America/Puerto_Rico (−3:00 war time 1942–45), all 960/960 vs backzone. Still open: **Bahamas**
  (EST/DST case, separate follow-up), **Cayman**, and the sub-hour/link-agreeing tail
  (St-Barth/St-Martin, Bonaire, the SSS islands).
- **Central-Africa whole-hour cluster** ✅ COMPLETE (WAT +1:00 vs the Lagos link, which
  reached WAT only 1 Sep 1919 → default 30–47 min slow ~1912–1919): Cameroon ✅, CAR ✅,
  Congo-Brazzaville ✅, Gabon ✅, Angola ✅ (early standardizer: +0:52 Luanda MT from 1892).
  Equatorial Guinea ✅ (GQ_1, done earlier). Verified iana-sufficient no-op: **Chad**
  (Africa/Ndjamena is a real zone). Deferred: **Zaire/Congo-Kinshasa** ⏳ — genuine two-zone
  (+1:00 west, +2:00 east; 3 Shanks tables) → needs a west/east division split.
- **East Africa (EAT cluster)** — still open (all default-Linked to Africa/Nairobi, mostly
  SUB-HOUR 15–30 min gaps): Uganda, Ethiopia, Eritrea, Somalia, Djibouti, Madagascar, Comoros,
  Réunion, Seychelles. Tanzania ✅ (TZ_1, done earlier). Kenya = Nairobi = the anchor (no-op).
- **Asia/Pacific**: Brunei ✅ (BN_1, +7:30/+8 vs Kuching link), Kuwait ✅ (KW_1, sub-hour
  Al-Kuwayt MT +3:11:56 vs Riyadh link). Deferred: **Laos ⏳ / Cambodia (Kampuchea) ⏳** — both
  Shanks tables invent a +8:00 (120E00) peacetime span 1/May/1912–1/May/1931 that IANA's
  authoritative primary-sourced Indochina history (Trần Tiến Bình 2005 + government gazette
  decrees, in the `asia` file) contradicts (continuous +7 1911–1942), and omit the documented
  WWII +8/+9 (1942–1945) → sourced-primary-beats-Shanks defer, like Sierra Leone/Ghana. Still
  open: **Oman** (Muscat +3:54:24 vs Dubai link, sub-hour), **Bahrain** (+3:22:20, backzone has
  1941/1944 ordinance dates — verify vs Shanks), **Malaysia** (multi-transition +7:xx→+7:30→…,
  Singapore-link, complex), Micronesia (Pohnpei/Chuuk, Guadalcanal/Port-Moresby links), **Saipan**
  (Guam link, +9 WWII — but IANA notes Shanks's Saipan +09 is doubted → verify carefully).

**Skip as noise** (dateline artifacts / uninhabited / alias mislabels): Midway, Wake, Enderbury,
Kerguelen, Jan Mayen, Johnston, Christmas/Cocos (verify), and any <20m LMT-residue rows that
resolve to already-standardized capitals (low birth-record impact).

_Country → atlas page for a worked country: locate on first touch (header scan, as for NL) or
from the back-of-book index (PDF ~448–455)._
