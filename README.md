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

### Rebuilding the synthetic zones

The compiled TZif blobs under `data/shanks/zoneinfo/` are committed, so the gem
has no runtime dependency on `zic`. After editing a `.zic` source:

```
rake shanks:build
```

## Provenance & scope

Time-zone transition dates are **facts**, not creative expression, and facts are
not copyrightable (*Feist v. Rural*; cf. *Astrolabe v. Olson*, which upheld the
public tz database). This gem re-expresses those facts as its own TZif and GeoJSON
and cross-checks them against the public-domain IANA database wherever the two
overlap (see the Kentucky #69 gold-standard equivalence test). No verbatim atlas
tables are shipped.

Coverage today is Kentucky plus the flat-offset overrides carried over from
harmonic-explorer; more states are added as their Shanks tables are transcribed
and IANA-cross-checked.

## License

MIT (code). See `LICENSE.txt`.
