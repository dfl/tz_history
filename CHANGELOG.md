# Changelog

All notable changes to `tz_history` are documented here. This project adheres to
[Semantic Versioning](https://semver.org).

## [0.2.0] - 2026-09-11

Full contiguous-US coverage. Every one of the **48 CONUS states** has been worked
against the Shanks *American Atlas* TIME TABLES, crop-verified against the atlas
page, and cross-checked against IANA. See `docs/COVERAGE.md` for the per-state
disposition and `docs/DEFERRED.md` for known residuals.

### Added
- Coverage for all 48 contiguous states (previously Kentucky + flat overrides only),
  spanning five disposition patterns:
  - **IANA-sufficient** — modern zone already matches history (e.g. Arizona, California).
  - **Flat standard-time overrides** — no-DST majorities mapped to `Etc/GMT±N`
    (Mississippi/Oklahoma/South Carolina CST/EST; New Mexico/Utah/Wyoming MST;
    Oregon/Washington PST for their no-DST decades).
  - **Two-zone town splits** — states straddling a zone boundary resolved town-by-town
    via the nearest documented Shanks town: **Ohio** (western Central-until-1927 vs
    Eastern), the Central/Mountain **Dakotas** and **Nebraska**, plus far-west-Pacific
    edges of Utah/Arizona.
  - **Staggered-adoption cohort nests** — seaboard states that dropped daylight saving
    town-by-town at different years: **New York**, **Pennsylvania** (pre-war core),
    **Vermont**, Maine, New Hampshire, New Jersey.
  - **Flagged, not guessed** — contested/incomplete regions return a `note` caveat while
    `for` defers to IANA (e.g. patchy postwar Virginia/West Virginia, far-west Arizona
    Pacific, Illinois/Indiana/Michigan pending dedicated passes).
- `note` now surfaces uncertainty for regions we deliberately do **not** silently
  correct, so a UI can prompt the user to verify the birth record.

### Fixed
- City-index county numbers: `tools/extract_cities.rb` gained a coordinate-derived
  county# repair (`--counties=`), point-in-polygon + majority-learned per-county
  numbering, correcting ~6,500 OCR misreads across the research indices without
  shifting correctly-numbered majorities. (Metadata only — runtime lookups resolve by
  coordinate, not county#.)

### Notes
- Alaska and Hawaii remain out of scope (single modern zones).
- Runtime is unchanged: point-in-polygon over `data/us_historical_zones.geojson`,
  returning `TZInfo::Timezone`; no `zic`/network dependency (compiled zones ship).

## [0.1.0]

Initial extraction from the harmonic-explorer HistoricalZone service: the
point-in-polygon engine, flat-offset overrides, and Shanks transition-list zones
compiled via `zic` (Kentucky #69/#71 gold-standard IANA equivalence).
