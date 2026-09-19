# tz_history

Historical US timezones for **pre-1970 births**, where the IANA/Olson database
only models the *modern* zone.

IANA guarantees local time-zone observance only since 1970 and assigns every
coordinate its present-day zone. A plain geographic lookup therefore mis-zones a
place that historically kept different clocks: East Tennessee ran Central until
its 1946-1949 switch to Eastern; western Georgia kept CST (no daylight saving)
until 1941; northern Kentucky observed daylight-saving *summers* 1920-1926 before
switching to Eastern standard. The astrology-standard Shanks *American Atlas*
records these; IANA deliberately does not.

`tz_history` corrects a documented set of these cases by point-in-polygon against
actual US county boundaries, returning a `TZInfo::Timezone`.

## Installation

```ruby
# Gemfile
gem "tz_history"
```

or `gem install tz_history`. Requires Ruby >= 3.2; the only runtime dependency is
`tzinfo`. The compiled zone data ships in the gem, so there is no build step or
network access at runtime.

## Usage

```ruby
require "tz_history"

# Knoxville, TN before the 1946 switch -> fixed CST (correct in summer too)
TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1946-01-15").identifier
# => "Etc/GMT+6"

# Covington, KY, summer 1923 -> CDT, a seasonal DST a flat offset cannot hold
tz = TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1923-07-15")
tz.identifier                                             # => "Shanks/KY_71"
tz.period_for_local(Time.utc(1923, 7, 15, 12)).observed_utc_offset
# => -18000  (-05:00, Central Daylight)

# No documented correction -> nil (use the geocoded IANA zone)
TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1990-01-15")   # => nil
```

### API

- `TzHistory.for(lat:, lon:, date:) => TZInfo::Timezone | nil` — the historical
  zone to substitute, or `nil` when there is no documented correction.
- `TzHistory.zone_id(lat:, lon:, date:) => String | nil` — just the identifier.
- `TzHistory.note(lat:, lon:, date:) => String | nil` — a human-readable prompt to
  verify the birth record (also returned for *contested* regions we flag but do
  **not** silently correct).

`date` is the wall-clock birth date (a `"YYYY-MM-DD"` string or a `Date`).

### In a Rails app

`for` returns a raw `TZInfo::Timezone`. To get `.parse`/`.local`, wrap it:

```ruby
tz = TzHistory.for(lat:, lon:, date:)
tz && ActiveSupport::TimeZone.create(tz.identifier, nil, tz)
```

## Coverage

All **48 contiguous US states** have been worked against the Shanks *American
Atlas* TIME TABLES (Alaska/Hawaii are out of scope — single modern zones). Each
state's disposition is recorded in [`docs/COVERAGE.md`](docs/COVERAGE.md); the
patterns are:

- **IANA already sufficient** — the modern zone matches history (e.g. Arizona,
  California). No override; `for` returns `nil`.
- **Flat standard-time override** — a state/region that kept one standard offset
  with no daylight saving maps to a fixed `Etc/GMT±N` (the no-DST Central/Eastern/
  Mountain/Pacific majorities: Mississippi, New Mexico, Oregon, …).
- **Two-zone town split** — states straddling a zone boundary resolve town-by-town
  via the nearest documented Shanks town (Ohio's Central-vs-Eastern west, the
  Central/Mountain Dakotas, far-west-Pacific Utah/Arizona edges, …).
- **Staggered-adoption cohort nest** — the seaboard states that dropped daylight
  saving town-by-town at different years (New York, Pennsylvania, Vermont, …).
- **Flagged, not guessed** — contested or incompletely-documented regions return a
  `note` caveat while `for` defers to IANA.

Known residual minorities and a handful of contested tails (e.g. Michigan's
eastern-LP towns, Indiana's undocumented boundary counties) are tracked in
[`docs/DEFERRED.md`](docs/DEFERRED.md).

### International

Internationally IANA is *not* silent — it models the whole world pre-1970 — but it
distrusts a lot of its own pre-1970 data and demotes it out of the default build via
`Link`, e.g. `Europe/Amsterdam` is just a link to `Europe/Brussels` (GMT/WET) before
1940. `tz_history` ships a Shanks *International Atlas* correction for every country
where that demotion actually mis-zones a birth by a material amount, checked
offset-for-offset against IANA's own `backzone` data wherever it exists. Country
polygons come from the public-domain Natural Earth dataset
(`data/intl_historical_zones.geojson`); full detail and per-country cross-check
numbers are in [`docs/INTL_COVERAGE.md`](docs/INTL_COVERAGE.md).

60+ countries/territories ship a correction:

- **Europe** — Netherlands, Iceland, Luxembourg, Norway, Sweden, Denmark, and
  Ukraine's Transcarpathia (Uzhhorod/Mukachevo), all sub-hour or CET/link
  mismatches against Berlin/Brussels-linked defaults.
- **West Africa** (whole-hour, vs the Abidjan/Lagos GMT links) — Senegal, Guinea,
  Mauritania, Mali, Gambia, Niger, Sierra Leone, Benin.
- **Central Africa** (WAT, vs the Lagos link) — Cameroon, Central African
  Republic, Congo-Brazzaville, Gabon, Angola, Equatorial Guinea, and DR Congo
  (Zaire), split west/east by province since it straddles WAT/CAT.
- **East Africa / Indian Ocean** (sub-hour, vs the Nairobi/Dubai links) —
  Ethiopia, Eritrea, Somalia (+ Somaliland), Djibouti, Uganda, Madagascar,
  Comoros, Mayotte, Réunion, Seychelles, Tanzania.
- **Southern Africa** (vs the Maputo/Johannesburg CAT/SAST links) — Malawi,
  Botswana, Eswatini, Lesotho, Zimbabwe, Zambia.
- **Caribbean** (AST/EST, vs the Puerto Rico link's 1942–45 War Time and the
  Bahamas' Toronto-style DST link) — Aruba, Curaçao, Anguilla, Antigua &
  Barbuda, Dominica, Grenada, Guadeloupe, Montserrat, St Kitts & Nevis, St
  Lucia, St Vincent, Trinidad & Tobago, both Virgin Islands, and the Bahamas.
- **Middle East / Asia** — Brunei, Kuwait, Oman, Bahrain, Yemen, and China
  (the Long-shu/Chongqing +7:00 zone across Sichuan/Gansu/Qinghai/Inner
  Mongolia/Hainan, and the Kashgar/Kunlun +5:30→+5:00 zone in far-west
  Xinjiang, both vs Beijing-time defaults).
- **North America** — five Canadian localities straddling Ontario/Quebec DST
  and zone-boundary quirks (Rainy River District, Thunder Bay, Nipigon,
  Montreal), and Ensenada, Mexico (Pacific/Mountain flips 1922–1949).

Countries checked and found already correct under IANA's default (no override
needed) or explicitly deferred because Shanks conflicts with a better-sourced
IANA primary are listed in `docs/INTL_COVERAGE.md`, along with the remaining
open backlog.

## How it works

Two kinds of correction share one point-in-polygon lookup over a FeatureCollection
of county polygons (`data/us_historical_zones.geojson`, public-domain US Census
boundaries):

1. **Flat overrides** — a county that kept a single standard offset year-round
   maps to a fixed IANA zone (`Etc/GMT+6` etc.). Winter/standard cases are exact;
   summer is correct because the fixed offset never applied the DST IANA assumes.
2. **Shanks transition-list zones** — a county with a *seasonal* pre-1970 DST
   history that no flat offset can represent maps to a synthetic zone. Each Shanks
   TIME TABLE is compiled by `zic` (the reference tzdata compiler) into a real
   TZif file, resolved by TZInfo through the same code path as any IANA zone.

Contested boundaries where the pre-1970 history is genuinely uncertain are
**flagged, not guessed** (`note` returns a caveat; `for` returns `nil`).

International overrides share the same lookup against a second FeatureCollection
of country/province polygons (`data/intl_historical_zones.geojson`, Natural Earth
boundaries) instead of US counties; everything else — flat vs. Shanks
transition-list zones, `zic` compilation, the flag-don't-guess rule — is identical.

### Rebuilding the synthetic zones

The compiled TZif blobs under `data/shanks/zoneinfo/` are committed, so the gem
has no runtime dependency on `zic`. After editing a `.zic` source:

```
rake shanks:build
```

### Relationship to IANA / tzcode

This gem is a pre-1970 *correction layer* over IANA, not a replacement. The
synthetic zones are compiled with `zic` and validated with `zdump` from the
[`tzcode`](https://github.com/valodzka/tzcode) distribution (the reference
implementation behind the IANA [tz database](https://www.iana.org/time-zones));
at runtime the committed TZif blobs are read through `tzinfo` like any IANA zone.

## Provenance & scope

Time-zone transition dates are **facts**, not creative expression, and facts are
not copyrightable (*Feist v. Rural*; cf. *Astrolabe v. Olson*, which the tz-database
maintainers survived — the rights-holder to the same Shanks atlases sued over exactly
this activity and withdrew). This gem re-expresses those facts as its own TZif and
GeoJSON, cross-checks them against the public-domain IANA database wherever the two
overlap (see the Kentucky #69 gold-standard equivalence test), and gates every shipped
zone behind a visual crop-verify of the atlas page it came from. The atlas itself and any
verbatim OCR of it are referenced, never redistributed — see
[`docs/PROVENANCE.md`](docs/PROVENANCE.md) for the full sourcing and copyright posture.

## License

MIT (code). See `LICENSE.txt`.
