# International Atlas — extraction plan (all countries)

How to grow `tz_history` from the Netherlands pilot to worldwide pre-1970 coverage
by transcribing the Shanks *International Atlas* (Revised 3rd ed., 1985) TIME TABLES
into synthetic zones — the international counterpart of `docs/EXTRACTION.md`.

The engine (Part A) and the US sweep are done. This is the same disciplined,
human-in-the-loop data entry with automated safety nets, done **country by country**,
each country a self-contained, verifiable unit.

---

## 0. Shape of the book (grounded)

- 456 PDF pages. **Front matter** PDF 1–24 (title, "How to use" in 5 languages,
  sidereal-time math). **Countries** run alphabetically **Afghanistan (PDF 25) →
  Zimbabwe (~PDF 432)**. **Back-of-book INDEX** PDF ~448–455 maps each country to its
  printed page (with cross-references, e.g. *Zimbabwe → Rhodesia*). **Printed page =
  PDF − 24.** Source PDF stays local/uncommitted (copyright; facts only extracted):
  `~/work/scrapers/Archive.org-Downloader/the_international_atlas.pdf`.
- **Row schema is identical to the American Atlas**, keyed by country + optional
  division# instead of state/county:
  `Name  div#  table#  LAT  LON  GMT-equiv` (city listings, 3 columns/page).
- **Time-table cells give an EXPLICIT GMT offset** (`-6:30`), east = negative — no
  zone-code decoding (easier than CST/EDT). DST is the offset shifting by an hour
  (sometimes 0:20 / 0:30 / 0:40 / 2:00). `Begin Standard <meridian>` lines set the
  base offset from a longitude meridian (e.g. `4E53` = +0:19:32).

## 1. The reframe that bounds the work — divergence-first

Unlike the US (where IANA is deliberately silent sub-state), **IANA models the whole
world pre-1970**. But it distrusts its own pre-1970 data (much of it from the same
astrology atlases; `theory.html`: *"astrology books… invented entries"*) and has
**demoted a lot of it out of the default build** — merged zones to bare `Link`s and
quarantined detail in the opt-in `backzone`. So most countries need **no work**: the
default build is already correct pre-1970. The job is the **subset where Shanks beats
the shipped answer**.

**Three-way triage per country/zone (scriptable — Phase 0):**

| Signal (grep IANA source) | Meaning | Disposition |
|---|---|---|
| zone is a `Link` in `backward` (e.g. Amsterdam→Brussels) | default build gives the *wrong country's* pre-1970 history | **OVERRIDE — high value** |
| full history only in `backzone` (opt-in, rarely compiled) | default build simplified/GMT-ish | **OVERRIDE — high value** |
| region file (`europe`/`asia`/…) has a **sourced primary** contradicting Shanks (e.g. *"go with Oja over Shanks"*) | IANA better-sourced | **DEFER + flag** |
| region file effectively == Shanks, well-sourced | agree | **IANA-sufficient — no-op** |

This turns "which of ~200 countries matter?" into a computed, ranked worklist.

## 2. Resolution models (by country shape)

- **Single dominant zone** (one table, whole country) → **country-polygon override**
  (the Netherlands template: one `Etc/GMT` or `Shanks/<CC>_1` feature over the country
  polygon, date-windowed). Cheapest; no city extraction needed.
- **Multi-zone / divisions** (provinces, e.g. Germany DDR/BRD, USSR, Australia, Brazil,
  Canada, India, Mexico, Indonesia) → **sub-national admin_1 polygons** *or*
  **nearest-city over the atlas's own geocoded cities** (the atlas gives lat/lon +
  table# for every town). Requires the intl `extract_cities` path + a split feature.
- **Contested / "estimated from incomplete data"** → **flag, don't guess** (a `warn`
  note; `for` defers to IANA), exactly as the US contested regions.

## 3. Phases

**Phase 0 — Inventory & triage (compute once).**
1. OCR the back index (PDF ~448–455) → `tools/intl_atlas_pages.tsv`
   (`country → printed page → PDF page`, resolving cross-references).
2. Build `tools/iana_divergence.rb`: for each country's IANA zone(s), grep `backward`
   (Link?), `backzone` (demoted?), and the region file (Shanks-cited? primary source?)
   → a disposition + a value score.
3. Seed `docs/INTL_COVERAGE.md` with one row per country and its **predicted**
   disposition (override / defer / iana-sufficient) + population + difficulty.

**Phase 1 — Single-zone override sweep (bulk fast wins).**
Every country that is one dominant zone **and** a default-build gap → an NL-style
country-polygon override. Most of the shippable value, cheaply. (Sub-hour LMT-based
standard offsets — France's Paris Mean Time, Ireland's Dublin MT, etc. — land here.)

**Phase 2 — Multi-division countries (dedicated).**
Build the intl `extract_cities` + admin_1 polygons; ship nearest-city / province split
features. The giants (USSR, Germany, Australia, Brazil, Canada, India, China, Mexico).

**Phase 3 — Long tail + contested.**
Small single-zone countries already IANA-sufficient close out as "verified no-op";
contested/estimated regions ship a `warn`. Nothing silently guessed.

## 4. Per-country pipeline (the runbook, unchanged in spirit)

For each country worked:
1. **Render** the tt page(s) (`render_state.rb`, 220–300 DPI, `--autocols` for cities).
2. **Transcribe** each qualifying table, **visual-verified** against the crop (OCR is a
   draft, never the source of truth — the PA lesson).
3. **Author `.zic`** via `tools/zic_from_json.rb` (spec carries `"atlas":"international"`).
   Base offsets in seconds (sub-hour OK); DST is the `dst` flag.
4. **Cross-check** — compile IANA's `backzone`/region zone and diff offsets month-by-
   month across the overlap (the NL gold test: `Shanks/NL_1` ≡ backzone Amsterdam
   575/575). No IANA counterpart → hand assertions.
5. **Features** — country polygon (Natural Earth admin_0) or province/nearest-city, into
   `data/intl_historical_zones.geojson`, date-windowed; compact one-line geometry.
6. **Tests** + **ledger row** (`docs/INTL_COVERAGE.md`). `rake test` green; US untouched.

Never skip 2 or 4 — blind OCR is a silent 1-hour error, the bug we exist to fix.

## 5. Tooling to build / adapt

| Tool | Status | Purpose |
|------|--------|---------|
| `tools/intl_atlas_pages.tsv` | **new (Phase 0)** | country → printed/PDF page, from the back index |
| `tools/iana_divergence.rb` | **new (Phase 0)** | the three-way triage; ranks the worklist |
| `tools/zic_from_json.rb` | ✅ done | now honors `"atlas":"international"` |
| `tools/extract_cities.rb` | adapt | intl rows are `Name div# table# LAT LON GMT` (div# in the county# slot) |
| `research/intl/build_<cc>.rb` | per-country | emits polygon/city features (NL is the template) |
| polygon source | **new** | Natural Earth admin_0 + admin_1 (PUBLIC DOMAIN); filter to the relevant landmass |
| `tools/add_feature.rb` | adapt | generalize to write intl features (compact geometry) |

## 6. Prioritization

Order by **population × divergence value** (not strict alphabetical). Highest first:
big-population countries whose IANA zone is a Link/backzone (default build wrong), and
sub-hour-LMT countries where a flat modern offset mis-zones early births. Single-zone
countries before multi-division ones (speed). Log every defer/warn so "N countries
done" never reads as "everything covered."

## 7. Provenance & legal (unchanged discipline)

Time-zone transition dates, coordinates, and place names are **facts** — not
copyrightable (*Feist*; cf. *Astrolabe v. Olson*). Ship **no verbatim atlas tables or
prose**, only re-expressed transition lists; each `.zic` header records provenance
(printed page, table #, cross-check); the atlas PDF stays local. Country/province
polygons come from **public-domain Natural Earth**. Cross-check against public-domain
IANA wherever they overlap. See `docs/PROVENANCE.md`.

## 8. Definition of done (per country)

- Every qualifying table transcribed, visual-verified, compiled.
- Cross-check passes (backzone/region twin) or hand assertions for the rest.
- Features added (compact geometry), date-windowed; contested cases `warn`-ed and logged.
- `rake test` green; US overrides unchanged.
- `docs/INTL_COVERAGE.md` row updated; `.zic` provenance complete.

Kentucky was the US seed; **the Netherlands is the international seed** (`Shanks/NL_1`,
committed). Phase 0 is the immediate next step.
