# frozen_string_literal: true

require "test_helper"

# Public API tests. These exercise the point-in-polygon lookup and the two kinds
# of correction the gem ships: flat IANA-zone overrides and full Shanks
# transition-list zones. Uses a handful of representative coordinates rather than
# the app's full fixture set (which lives upstream in harmonic-explorer).
class TzHistoryTest < Minitest::Test
  include TestHelpers

  # --- flat-offset overrides (winter/standard exact; summer via substitute zone) ---

  def test_east_tennessee_pre_switch_is_fixed_cst
    tz = TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1946-01-15") # Knoxville
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_east_tennessee_post_switch_is_fixed_est
    tz = TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1950-07-01")
    assert_equal "Etc/GMT+5", tz.identifier
  end

  def test_zone_id_convenience
    assert_equal "Etc/GMT+6", TzHistory.zone_id(lat: 35.9606, lon: -83.9207, date: "1946-01-15")
  end

  # --- Shanks transition-list zone (northern KY, table #71) ---

  def test_northern_ky_summer_1923_is_cdt_not_flattened_cst
    # Covington (Kenton Co.): the 1920-1926 daylight summers a flat CST could not hold.
    tz = TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1923-07-15")
    assert_equal "Shanks/KY_71", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1923-07-15")) # CDT
  end

  def test_northern_ky_winter_1923_is_cst
    assert_equal(-6 * 3600, offset_of(TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1923-01-15"), "1923-01-15"))
  end

  def test_northern_ky_after_1926_switch_is_eastern_standard
    assert_equal(-5 * 3600, offset_of(TzHistory.for(lat: 39.0837, lon: -84.5086, date: "1930-07-15"), "1930-07-15"))
  end

  # --- Shanks transition-list zone (Alabama 1941 summer DST, table AL #1) ---

  def test_alabama_summer_1941_is_shanks_cdt_not_flattened_cst
    # Birmingham (Jefferson Co.): Jul 21 - Oct 1 1941 Alabama observed CDT, which the
    # flat Etc/GMT+6 override skips and IANA America/Chicago (no 1941 DST) also misses.
    tz = TzHistory.for(lat: 33.5207, lon: -86.8025, date: "1941-08-15")
    assert_equal "Shanks/AL_1", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1941-08-15")) # CDT
  end

  def test_alabama_before_the_1941_dst_window_is_the_flat_cst_override
    # A June 1941 birth is before Jul 21, so the flat CST override still applies.
    tz = TzHistory.for(lat: 33.5207, lon: -86.8025, date: "1941-06-15")
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_alabama_after_the_1941_dst_window_defers_to_iana
    # After the Oct 1 fallback the state is back on plain CST, which IANA models
    # correctly, so we defer (return nil) rather than substitute.
    assert_nil TzHistory.for(lat: 33.5207, lon: -86.8025, date: "1941-11-15")
  end

  def test_alabama_georgia_line_county_keeps_its_warn_in_summer_1941
    # Auburn (Lee Co.) is one of the east-Alabama Georgia-line counties that keep
    # Eastern de facto -- it stays a warn (defers to IANA), NOT forced onto AL_1.
    assert_nil TzHistory.for(lat: 32.6099, lon: -85.4808, date: "1941-08-15")
    note = TzHistory.note(lat: 32.6099, lon: -85.4808, date: "1941-08-15")
    assert_match(/Georgia line/i, note)
  end

  # --- flat EST override where IANA over-applies early-1920s NYC daylight ---
  # Rural/interior Connecticut kept EST year-round through the early-mid 1920s, but
  # IANA America/New_York applies NYC's continuous 1920-1925 summer DST statewide.

  def test_rural_connecticut_summer_1922_is_fixed_est_not_iana_edt
    # Torrington (Litchfield Co.): a flat Etc/GMT+5 corrects IANA's spurious EDT.
    tz = TzHistory.for(lat: 41.8007, lon: -73.1212, date: "1922-07-15")
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1922-07-15")) # EST, not EDT
  end

  def test_rural_connecticut_after_1926_defers_to_iana
    # From 1926 Connecticut generally observed DST (matching IANA), so we defer.
    assert_nil TzHistory.for(lat: 41.8007, lon: -73.1212, date: "1930-07-15")
  end

  def test_urban_connecticut_county_is_a_warn_split_not_an_override
    # Bridgeport (Fairfield Co.): the city ran DST from 1920 but surrounding towns did
    # not -- a genuine straddle, so we warn and defer rather than guess.
    assert_nil TzHistory.for(lat: 41.1792, lon: -73.1894, date: "1922-07-15")
    note = TzHistory.note(lat: 41.1792, lon: -73.1894, date: "1922-07-15")
    assert_match(/larger cities/i, note)
  end

  # --- flat MST override where IANA over-applies early-1920s Denver daylight ---
  # Rural/mountain Colorado kept MST year-round in 1920-1921, but IANA America/Denver
  # applies Denver-metro summer DST (1920, spring 1921) statewide.

  def test_rural_colorado_summer_1920_is_fixed_mst_not_iana_mdt
    # Grand Junction (Mesa Co.): flat Etc/GMT+7 corrects IANA's spurious MDT.
    tz = TzHistory.for(lat: 39.0639, lon: -108.5506, date: "1920-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1920-07-15")) # MST, not MDT
  end

  def test_rural_colorado_after_1921_defers_to_iana
    assert_nil TzHistory.for(lat: 39.0639, lon: -108.5506, date: "1922-07-15")
  end

  def test_denver_kept_its_1920_dst_and_defers_to_iana
    # Denver Co. observed the 1920 DST IANA models, so we defer rather than override.
    assert_nil TzHistory.for(lat: 39.7392, lon: -104.9903, date: "1920-07-15")
  end

  def test_denver_metro_split_county_is_a_warn
    # Adams Co.: Denver suburbs on DST, outlying towns on MST -- a straddle, so warn.
    assert_nil TzHistory.for(lat: 39.9853, lon: -104.8206, date: "1920-07-15")
    note = TzHistory.note(lat: 39.9853, lon: -104.8206, date: "1920-07-15")
    assert_match(/Denver metro/i, note)
  end

  # --- rural Delaware: EST 1920-1941 where IANA applies continuous Philly/NYC DST ---

  def test_rural_sussex_delaware_summer_1925_is_fixed_est
    tz = TzHistory.for(lat: 38.6901, lon: -75.3855, date: "1925-07-15") # Georgetown
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1925-07-15")) # EST, not EDT
  end

  def test_rural_sussex_delaware_after_war_defers_to_iana
    assert_nil TzHistory.for(lat: 38.6901, lon: -75.3855, date: "1948-07-15")
  end

  def test_kent_delaware_is_a_town_by_town_warn_split
    assert_nil TzHistory.for(lat: 39.1582, lon: -75.5244, date: "1925-07-15") # Dover
    note = TzHistory.note(lat: 39.1582, lon: -75.5244, date: "1925-07-15")
    assert_match(/town-by-town/i, note)
  end

  # --- Atlanta local DST 1937-1940 (Shanks GA #21), an exclusion guard ---
  # The city of Atlanta observed summer DST 1937-1940 (EDT), which IANA models
  # correctly but the statewide Georgia EST no-DST override would flatten. A note-less
  # guard over Fulton + DeKalb blocks the override for 1937-1940 so they defer to IANA.

  def test_atlanta_1938_summer_defers_to_iana_for_its_local_dst
    # Fulton Co.: without the guard the statewide no-DST override wins; with it, defer.
    assert_nil TzHistory.for(lat: 33.749, lon: -84.388, date: "1938-07-15")
  end

  def test_dekalb_1939_summer_defers_to_iana_for_its_local_dst
    assert_nil TzHistory.for(lat: 33.7748, lon: -84.2963, date: "1939-07-15") # Decatur
  end

  def test_atlanta_guard_only_covers_the_dst_years
    # Outside 1937-1940 the guard does not apply (Savannah stays on the EST override).
    tz = TzHistory.for(lat: 32.0809, lon: -81.0912, date: "1938-07-15") # Savannah, EST override
    assert_equal "Etc/GMT+5", tz.identifier
  end

  # --- Atlanta-metro Central-set bug fix (was mis-zoned Central 1919-41) ---
  # Fulton (Atlanta) + Cobb/Clayton/Cherokee/Forsyth were wrongly included in the
  # Western-Georgia Central set (Etc/GMT+6), so outside the 1937-40 guard they read
  # Central -- a 1 h error. They are Eastern (like DeKalb): removed from the Central
  # features, they now fall through to the statewide Georgia EST override (Etc/GMT+5).

  def test_atlanta_metro_is_eastern_standard_not_central_1925
    # 1925 is outside the 1937-40 guard; before the fix Fulton resolved Etc/GMT+6.
    %w[fulton cobb clayton cherokee forsyth].zip(
      [[33.749, -84.388], [33.94, -84.57], [33.54, -84.36], [34.24, -84.48], [34.23, -84.13]]
    ).each do |name, (lat, lon)|
      tz = TzHistory.for(lat: lat, lon: lon, date: "1925-06-01")
      assert_equal "Etc/GMT+5", tz.identifier, "#{name} should be Eastern (EST), not Central"
    end
  end

  def test_true_western_georgia_stays_central_1925
    # Columbus (Muscogee) + LaGrange (Troup) are genuinely Central -- unchanged.
    [[32.4610, -84.9877], [33.0362, -85.0319]].each do |lat, lon|
      tz = TzHistory.for(lat: lat, lon: lon, date: "1925-06-01")
      assert_equal "Etc/GMT+6", tz.identifier
    end
  end

  # --- N/NE-mountain boundary counties: genuinely Central until the 1941 switch ---
  # Union/Fannin/Gilmer/Lumpkin/Dawson/Pickens/Bartow all cite Shanks GA #8 (crop-
  # verified, PDF 104): CST with NO peacetime daylight saving from 1919, switching to
  # Eastern on 1941-03-21. IANA models them America/New_York (Eastern) for all time, so
  # the pre-1941 CST is a real correction. This locks the timeline in place: DEFERRED #1
  # once worried these were "wrongly kept Central" -- the crop shows they belong there
  # pre-1941, and dropping them would reintroduce a 1 h error. The seats below resolve
  # via feat[40] (Etc/GMT+6, window 1919-10-26..1941-03-21) then the statewide EST.
  GA_MOUNTAIN_SEATS = {
    "Blairsville (Union)" => [34.8761, -83.9583], "Blue Ridge (Fannin)" => [34.8687, -84.3238],
    "Ellijay (Gilmer)" => [34.6939, -84.4822], "Dahlonega (Lumpkin)" => [34.5325, -83.9850],
    "Dawsonville (Dawson)" => [34.4211, -84.1192], "Jasper (Pickens)" => [34.4678, -84.4292],
    "Cartersville (Bartow)" => [34.1650, -84.8000]
  }.freeze

  def test_ga_mountain_counties_are_central_no_dst_before_1941
    # Summer 1938 is inside the peacetime-DST era, but GA #8 had NO peacetime DST:
    # a flat Etc/GMT+6 (CST), not IANA's EDT and not America/Chicago's CDT.
    GA_MOUNTAIN_SEATS.each do |name, (lat, lon)|
      tz = TzHistory.for(lat: lat, lon: lon, date: "1938-07-15")
      assert_equal "Etc/GMT+6", tz.identifier, "#{name} should be CST (no DST) in 1938"
    end
  end

  def test_ga_mountain_counties_switch_to_eastern_after_1941
    # Post-1941 they follow GA #8's switch to Eastern -> statewide EST override.
    GA_MOUNTAIN_SEATS.each do |name, (lat, lon)|
      tz = TzHistory.for(lat: lat, lon: lon, date: "1946-06-15")
      assert_equal "Etc/GMT+5", tz.identifier, "#{name} should be Eastern (EST) in 1946"
    end
  end

  def test_ga_mountain_switch_straddles_march_1941
    # Blairsville (Union): CST just before the 1941-03-21 switch, Eastern just after.
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 34.8761, lon: -83.9583, date: "1941-02-15").identifier
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 34.8761, lon: -83.9583, date: "1941-06-15").identifier
  end

  # --- rural Maine: TOWN-LEVEL EST correction where IANA bakes in NYC's continuous DST ---
  # Shanks ME #1 towns kept EST with no peacetime daylight saving 1920-1954 (war time
  # excepted), but IANA America/New_York applies EDT every summer. Maine was town-by-town
  # (coastal/city towns observed DST, rural inland did not), so this is a nearest-town
  # split: no-DST towns (ME #1, and ME #2 pre-war) resolve to Etc/GMT+5, DST towns defer.
  # (Crop-verified ME #1/#2; PDF 229.)

  def test_rural_maine_no_dst_town_summer_1930_is_fixed_est
    tz = TzHistory.for(lat: 44.039, lon: -69.211, date: "1930-07-15") # North Cushing (ME #1)
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1930-07-15")) # EST, not IANA's EDT
  end

  def test_rural_maine_no_dst_town_postwar_summer_1950_is_fixed_est
    tz = TzHistory.for(lat: 43.907, lon: -69.516, date: "1950-07-15") # Pemaquid (ME #1)
    assert_equal(-5 * 3600, offset_of(tz, "1950-07-15"))
  end

  def test_maine_dst_city_town_defers_to_iana
    # Bangor (ME #14) adopted local DST in 1920 -- IANA already models it, so the town
    # layer defers rather than flattening to EST. This is the town-level win: a DST city
    # is NOT swept into the rural EST override the way a whole-county override would.
    assert_nil TzHistory.for(lat: 44.801, lon: -68.778, date: "1930-07-15") # Bangor (ME #14)
    assert_nil TzHistory.for(lat: 44.801, lon: -68.778, date: "1925-07-15")
  end

  # --- Maine adoption-year cohort nest (crop-verified PDF 229) ---
  # Every rural table follows ME #1 (EST, no DST) until it adopts US-standard DST, then
  # matches IANA. So a town is EST only in the window BEFORE its table's adoption; the
  # override defers afterward. Non-overlapping windows key off each cohort's adoption year.
  def test_maine_me7_is_est_before_1934_then_defers
    # Ash Point (ME #7) adopted DST 1934-04-29: EST in 1930, defers (IANA EDT) from 1934.
    tz = TzHistory.for(lat: 44.056, lon: -69.087, date: "1930-07-15")
    assert_equal(-5 * 3600, offset_of(tz, "1930-07-15"))
    assert_nil TzHistory.for(lat: 44.056, lon: -69.087, date: "1935-07-15")
  end

  def test_maine_me6_cohort_1932
    # Bradley (ME #6) adopted DST 1932-04-24: EST in 1931, defers (IANA EDT) from 1932.
    tz = TzHistory.for(lat: 44.9208, lon: -68.6286, date: "1931-07-15")
    assert_equal(-5 * 3600, offset_of(tz, "1931-07-15"))
    assert_nil TzHistory.for(lat: 44.9208, lon: -68.6286, date: "1935-07-15")
  end

  def test_maine_me1_stays_est_through_the_whole_prewar_and_postwar
    # Pemaquid (ME #1) never adopted peacetime DST -> EST across every window to 1954.
    %w[1925-07-15 1931-07-15 1937-07-15 1941-01-15 1950-07-15].each do |d|
      assert_equal "Etc/GMT+5", TzHistory.for(lat: 43.907, lon: -69.516, date: d).identifier,
                   "Pemaquid (ME #1) should be EST on #{d}"
    end
  end

  def test_maine_after_1955_uniform_dst_defers_to_iana
    # From 1955 (US#2) Maine observed uniform DST, matching IANA -> outside the override window.
    assert_nil TzHistory.for(lat: 44.039, lon: -69.211, date: "1960-07-15")
  end

  # --- Maine tables ME#39-49 recovery (tt spans PDF 229-230; the original --max-table=38
  # wrongly dropped ~230 towns on these real tables). Index rebuilt to 1188 towns. ---
  def test_maine_me44_recovered_est_before_1931
    # Beaver Dam (ME #44) adopted DST 1931: EST in 1928, defers after.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 43.2667, lon: -70.8667, date: "1928-07-15").identifier
    assert_nil TzHistory.for(lat: 43.2667, lon: -70.8667, date: "1935-07-15")
  end

  def test_maine_me45_recovered_est_through_prewar
    # Bancroft (ME #45) adopted DST 1946: EST every pre-war summer.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 45.6736, lon: -68.0314, date: "1940-07-15").identifier
  end

  def test_maine_me47_recovered_postwar_est_until_1949
    # Bas Alton (ME #47) adopted DST 1949: EST pre-war AND postwar 1946-1948, defers after.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 45.0333, lon: -68.7333, date: "1935-07-15").identifier
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 45.0333, lon: -68.7333, date: "1947-07-15").identifier
    assert_nil TzHistory.for(lat: 45.0333, lon: -68.7333, date: "1950-07-15")
  end

  # --- Massachusetts: MA #1 (98%) matches IANA; only rural western MA #2 diverges ---
  # Crop-verified (PDF 254): MA #1 = EST with continuous EDT every summer from 1920 (exactly
  # IANA America/New_York -- no residual). MA #2 (14 Franklin/Hampshire hill towns) kept EST
  # with NO daylight saving in summers 1920 & 1921, resuming DST in 1922. Town-level split.

  def test_western_ma_hill_town_is_est_in_1920_and_1921_summers
    # Leverett (MA #2): EST while IANA applies EDT, in both divergent summers.
    [["1920-07-15"], ["1921-07-15"]].each do |d,|
      tz = TzHistory.for(lat: 42.4519, lon: -72.5019, date: d)
      assert_equal "Etc/GMT+5", tz.identifier, "Leverett should be EST on #{d}"
      assert_equal(-5 * 3600, offset_of(tz, d))
    end
  end

  def test_western_ma_hill_town_matches_iana_outside_1920_1921
    # Before 1920 and from 1922 (DST resumed) MA #2 matches IANA -> no override.
    assert_nil TzHistory.for(lat: 42.4519, lon: -72.5019, date: "1919-07-15")
    assert_nil TzHistory.for(lat: 42.4519, lon: -72.5019, date: "1922-07-15")
  end

  def test_ma1_boston_defers_to_iana_always
    # Boston (MA #1) had continuous DST from 1920 -> IANA is correct, no override.
    assert_nil TzHistory.for(lat: 42.3601, lon: -71.0589, date: "1920-07-15")
  end

  # --- Maryland: TOWN-LEVEL EST correction, rural vs Baltimore, per-table postwar ---
  # Crop-verified (PDF 239): only MD #1 (greater Baltimore) observed peacetime DST 1920-41;
  # every other (rural) table kept EST while IANA applies continuous NYC EDT. Postwar was
  # per-table: most tables resumed DST in 1947, MD #7 held EST until 1948, MD #16 until 1954.
  # Modeled as non-overlapping windows so each town gets EST exactly until ITS table's year.

  def test_rural_maryland_summer_1930_is_fixed_est_not_iana_edt
    tz = TzHistory.for(lat: 39.704, lon: -79.448, date: "1930-07-15") # western MD (rural)
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1930-07-15")) # EST, not IANA's EDT
  end

  def test_baltimore_defers_to_iana_for_its_dst
    # Baltimore (MD #1) observed daylight time, which IANA models -- defer, don't flatten.
    assert_nil TzHistory.for(lat: 39.290, lon: -76.612, date: "1930-07-15")
  end

  def test_maryland_war_years_defer_to_iana
    # 1944 is war time (EWT), which IANA models -> outside the override window.
    assert_nil TzHistory.for(lat: 39.704, lon: -79.448, date: "1944-07-15")
  end

  def test_maryland_1947_resumer_town_is_est_1946_then_defers
    # A town whose table resumed DST in 1947: EST in summer 1946, defers from 1947.
    assert_equal(-5 * 3600, offset_of(TzHistory.for(lat: 39.704, lon: -79.448, date: "1946-07-15"), "1946-07-15"))
    assert_nil TzHistory.for(lat: 39.704, lon: -79.448, date: "1947-07-15")
  end

  def test_maryland_md7_town_held_est_through_1947
    # MD #7 towns resumed DST only in 1948, so 1947 is still EST; 1950 defers.
    assert_equal(-5 * 3600, offset_of(TzHistory.for(lat: 38.3953, lon: -75.4133, date: "1947-07-15"), "1947-07-15"))
    assert_nil TzHistory.for(lat: 38.3953, lon: -75.4133, date: "1950-07-15")
  end

  def test_maryland_md16_town_held_est_through_1953
    # MD #16 towns kept EST until US#4 uniform DST in 1954, so 1950 is EST; 1955 defers.
    assert_equal(-5 * 3600, offset_of(TzHistory.for(lat: 38.7006, lon: -76.9725, date: "1950-07-15"), "1950-07-15"))
    assert_nil TzHistory.for(lat: 38.7006, lon: -76.9725, date: "1955-07-15")
  end

  # --- north Idaho panhandle: PST 1946-1960 where IANA applies California DST ---
  # The 10 Pacific-zone counties kept Pacific Standard year-round from the end of war
  # time until DST resumed, but IANA America/Los_Angeles applies California summer DST in
  # 1948 and 1950-1960. The panhandle is now a TOWN-LEVEL split: most towns (Shanks ID #2)
  # kept PST through 1963, but the ID #1 towns -- including Coeur d'Alene -- resumed summer
  # DST in 1961. The correctness invariant is the OFFSET; which zone object serves a point
  # (Etc/GMT+8 vs Shanks/ID_1) depends on the nearest documented town, and both are PST in
  # a no-DST year like 1955/1948.

  def test_north_idaho_summer_1955_is_pst_not_iana_pdt
    # 1955 predates any Idaho DST resumption, so every panhandle town is PST (-8), not
    # IANA's spurious PDT -- whichever town the point snaps to.
    tz = TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1955-07-15") # Coeur d'Alene
    assert_equal(-8 * 3600, offset_of(tz, "1955-07-15")) # PST, not PDT
  end

  def test_north_idaho_summer_1948_is_pst
    # 1948 was California's first post-war DST year; the panhandle kept PST (-8).
    tz = TzHistory.for(lat: 46.4165, lon: -117.0177, date: "1948-07-15")
    assert_equal(-8 * 3600, offset_of(tz, "1948-07-15"))
  end

  def test_coeur_dalene_resumed_summer_dst_1962_via_town_layer
    # Coeur d'Alene is a Shanks ID #1 town: it resumed summer DST in 1961, three years
    # before the ID #2 majority. The old flat override wrongly forced PST 1961-63; the
    # town-level split resolves it to Shanks/ID_1 -> PDT (-7). This is DEFERRED #5, now fixed.
    tz = TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1962-07-15")
    assert_equal "Shanks/ID_1", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1962-07-15")) # PDT, matching IANA (not forced PST)
    assert_equal(-8 * 3600, offset_of(tz, "1962-01-15")) # but PST in winter
  end

  def test_lewiston_id12_also_resumed_summer_dst_1962
    # Lewiston (Nez Perce Co., Shanks ID #12) is another 1961-resumer -- all five resumer
    # tables (ID #1/#4/#7/#10/#12) share the identical in-window history, so they map to the
    # same crop-verified transition zone. Summer 1962 is PDT (-7), winter PST (-8).
    tz = TzHistory.for(lat: 46.4165, lon: -117.0177, date: "1962-07-15")
    assert_equal(-7 * 3600, offset_of(tz, "1962-07-15"))
    assert_equal(-8 * 3600, offset_of(tz, "1962-01-15"))
  end

  def test_north_idaho_id2_town_still_kept_pst_through_1963
    # An ID #2 town kept PST even in 1962 (no early DST resumption) -- unchanged by the
    # town layer, which corrects only the ID #1/#4/#7/#10/#12 resumers.
    tz = TzHistory.for(lat: 48.14, lon: -116.75, date: "1962-07-15") # a Shanks ID #2 town
    assert_equal(-8 * 3600, offset_of(tz, "1962-07-15"))
  end

  def test_north_idaho_war_time_defers_to_iana
    # A 1944 birth is before the override window (war time PWT, which IANA models).
    assert_nil TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1944-07-15")
  end

  # (Superseded: the old "Coeur d'Alene kept PST in 1962" test asserted the over-correction
  # bug -- Coeur d'Alene is an ID #1 town that resumed DST in 1961. The ID #2 "kept PST"
  # invariant is now checked with a real ID #2 coordinate above, and the Coeur d'Alene
  # correction by test_coeur_dalene_resumed_summer_dst_1962_via_town_layer.)

  def test_north_idaho_after_1964_dst_resumption_defers_to_iana
    # From spring 1964 the panhandle observed DST (matching America/Los_Angeles), so defer.
    assert_nil TzHistory.for(lat: 47.6777, lon: -116.7805, date: "1964-07-15")
  end

  # --- southern Idaho: MOUNTAIN from 1919 where IANA/Boise stays Pacific until 1923 ---
  # Eastern/central Idaho counties switched to Mountain time in 1919 (Shanks ID #13-16),
  # but IANA America/Boise keeps them Pacific until the official 1923-05-13 boundary move.

  def test_eastern_idaho_1921_is_fixed_mst_not_iana_pst
    # Pocatello (Bannock Co.): flat Etc/GMT+7 corrects Boise's spurious Pacific.
    tz = TzHistory.for(lat: 42.8713, lon: -112.4455, date: "1921-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1921-07-15")) # MST, not PST
  end

  def test_idaho_falls_1921_winter_is_fixed_mst
    # Idaho Falls (Bonneville Co.), the largest eastern-Idaho city.
    tz = TzHistory.for(lat: 43.4917, lon: -112.0339, date: "1921-01-15")
    assert_equal "Etc/GMT+7", tz.identifier
  end

  def test_eastern_idaho_after_1923_boundary_move_defers_to_iana
    # From 1923-05-13 America/Boise itself is Mountain, so we defer.
    assert_nil TzHistory.for(lat: 42.8713, lon: -112.4455, date: "1924-07-15")
  end

  def test_boise_matches_iana_and_defers
    # Ada Co. (Boise): its cities map to Shanks ID #18, which switched in 1923-05-13 --
    # exactly what America/Boise models -- so there is no residual to correct.
    assert_nil TzHistory.for(lat: 43.615, lon: -116.2023, date: "1921-07-15")
  end

  # --- town-by-town straddle counties resolved by nearest documented Shanks town ---
  # Custer + Power straddle the eastern Mountain-from-1919 bloc and the western
  # Boise-match region. A "split" feature embeds the Shanks CITY LISTINGS points and
  # snaps the birth coordinate to the nearest town, so each sub-region gets its own
  # answer instead of a whole-county warn.

  def test_custer_east_lost_river_resolves_to_mountain_override
    # Mackay (eastern Custer): nearest documented town is Mountain-from-1919 -> Etc/GMT+7.
    tz = TzHistory.for(lat: 43.9115, lon: -113.6103, date: "1921-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
    assert_equal(-7 * 3600, offset_of(tz, "1921-07-15"))
    assert_match(/nearest documented town/i, TzHistory.note(lat: 43.9115, lon: -113.6103, date: "1921-07-15"))
  end

  def test_custer_west_salmon_basin_defers_to_iana
    # Challis / Stanley (western Custer): nearest town matched Boise (Pacific until 1923).
    assert_nil TzHistory.for(lat: 44.2163, lon: -114.9361, date: "1921-07-15") # Stanley
    assert_match(/straddle/i, TzHistory.note(lat: 44.2163, lon: -114.9361, date: "1921-07-15"))
  end

  def test_power_northeast_resolves_to_mountain_override
    # Michaud (NE Power, by American Falls): Mountain-from-1919 -> Etc/GMT+7.
    tz = TzHistory.for(lat: 42.8900, lon: -112.6140, date: "1921-07-15")
    assert_equal "Etc/GMT+7", tz.identifier
  end

  def test_power_arbon_valley_defers_to_iana
    assert_nil TzHistory.for(lat: 42.4560, lon: -112.5680, date: "1921-07-15") # Arbon
  end

  def test_split_county_is_inert_outside_its_window
    # Before 1919-10-26 and after the 1923-05-13 Boise switch, no correction applies.
    assert_nil TzHistory.for(lat: 43.9115, lon: -113.6103, date: "1918-07-15")
    assert_nil TzHistory.for(lat: 43.9115, lon: -113.6103, date: "1924-07-15")
  end

  # --- downstate Illinois: CST where IANA/Chicago bakes in continuous Chicago DST ---
  # Illinois law required birth times recorded in CST until 1959-07-01, and downstate
  # clocks kept CST, but IANA America/Chicago applies Chicago's continuous summer DST.

  def test_downstate_illinois_summer_1930_is_fixed_cst_not_iana_cdt
    # Springfield (Sangamon Co.): flat Etc/GMT+6 corrects IANA's spurious CDT.
    tz = TzHistory.for(lat: 39.7817, lon: -89.6501, date: "1930-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1930-07-15")) # CST, not CDT
  end

  def test_downstate_illinois_postwar_summer_1950_is_fixed_cst
    # Peoria: still CST after the war, before the 1959 state-law change.
    tz = TzHistory.for(lat: 40.6936, lon: -89.5890, date: "1950-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_downstate_illinois_wartime_defers_to_iana
    # 1943 is inside the WWII CWT window (IANA models it), between the two CST windows.
    assert_nil TzHistory.for(lat: 39.7817, lon: -89.6501, date: "1943-07-15")
  end

  def test_downstate_illinois_after_1959_law_change_defers_to_iana
    # From 1959-07-01 downstate adopted daylight time (matching IANA), so defer.
    assert_nil TzHistory.for(lat: 39.7817, lon: -89.6501, date: "1960-07-15")
  end

  def test_chicago_metro_defers_to_iana_via_exclusion_guard
    # Cook Co. (Chicago) observed the continuous DST IANA models -- the metro
    # exclusion guard keeps it on IANA rather than the downstate CST override.
    assert_nil TzHistory.for(lat: 41.8781, lon: -87.6298, date: "1930-07-15")
  end

  # --- Indiana: pre-1970 Central/Eastern + DST chaos, flagged not corrected ---
  # Shanks calls Indiana "very complex ... contradictory ... not documented"; IANA's
  # eight America/Indiana/* sub-zones are best-guesses. We flag (warn) and defer rather
  # than assert a clock offset we cannot verify.

  def test_indiana_pre1970_defers_to_iana_with_a_verify_warning
    # Indianapolis (Marion Co.): no override, but a note prompts verification.
    assert_nil TzHistory.for(lat: 39.7684, lon: -86.1581, date: "1950-07-15")
    note = TzHistory.note(lat: 39.7684, lon: -86.1581, date: "1950-07-15")
    assert_match(/complex|contradictory|verify/i, note)
  end

  def test_indiana_after_1970_has_no_warning
    assert_nil TzHistory.note(lat: 39.7684, lon: -86.1581, date: "1975-07-15")
  end

  def test_indiana_chicago_corner_is_not_flagged
    # Gary (Lake Co.): the clean NW Chicago corner (America/Chicago) is excluded.
    assert_nil TzHistory.note(lat: 41.5934, lon: -87.3464, date: "1935-07-15")
  end

  # --- Iowa: CST through 1953 where IANA/Chicago bakes in continuous DST ---
  # Iowa is entirely Central and kept CST (no DST) until the mid-1950s adoption scatter
  # (earliest Shanks postwar DST is IA #8, 1954). Pre-war + 1946-1953 are universal CST.

  def test_iowa_postwar_1950_is_fixed_cst_not_iana_cdt
    tz = TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1950-07-15") # Des Moines
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1950-07-15")) # CST, not CDT
  end

  def test_iowa_1953_still_fixed_cst_before_the_1954_scatter
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1953-07-15").identifier
  end

  def test_iowa_from_1954_is_a_patchy_warn_not_an_override
    # From 1954 observance is town-by-town, so we defer to IANA with a verify note.
    assert_nil TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1958-07-15")
    assert_match(/patchy|diversity|verify/i, TzHistory.note(lat: 41.5868, lon: -93.6250, date: "1958-07-15"))
  end

  def test_iowa_wartime_defers_to_iana
    assert_nil TzHistory.for(lat: 41.5868, lon: -93.6250, date: "1943-07-15")
  end

  # --- Minnesota: dominant CST kept no DST until 1957 (verify the imported override) ---
  # Crop-verified (PDF 281): MN #1 (1543 index towns, 95%) is straight CST with no local
  # DST 1919-1957 (war time excepted), adopting DST on 1957-04-28 (US#1 1966), while IANA
  # America/Chicago applies CDT every summer. The pre-war + postwar Etc/GMT+6 overrides
  # (windows end exactly at the 1957 adoption) are correct for the dominant table.
  def test_rural_minnesota_1930_and_1950_are_fixed_cst_not_iana_cdt
    [%w[1930-07-15], %w[1950-07-15], %w[1956-07-15]].each do |d,|
      tz = TzHistory.for(lat: 44.9853, lon: -95.4731, date: d) # rural western MN (MN #1)
      assert_equal "Etc/GMT+6", tz.identifier, "rural MN should be CST on #{d}"
      assert_equal(-6 * 3600, offset_of(tz, d))
    end
  end

  def test_minnesota_from_1957_adoption_defers_to_iana
    # From the 1957-04-28 DST adoption MN matches IANA -> outside the override window.
    assert_nil TzHistory.for(lat: 44.9853, lon: -95.4731, date: "1958-07-15")
  end

  # --- Mississippi: pure CST, no peacetime DST at all until 1967 (verify the override) ---
  # Crop-verified (PDF 292): MS #1 (1423 index towns, 99%) is straight CST -- only war time
  # 1918-19/1942-45, no peacetime DST -- until the 1967-04-30 Uniform Act, while IANA
  # America/Chicago applies CDT. Pre-existing pre-war + postwar Etc/GMT+6 overrides cover it.
  def test_rural_mississippi_is_fixed_cst_not_iana_cdt
    [%w[1930-07-15], %w[1950-07-15], %w[1960-07-15]].each do |d,|
      tz = TzHistory.for(lat: 32.3642, lon: -88.7036, date: d) # Meridian (MS #1)
      assert_equal "Etc/GMT+6", tz.identifier, "Meridian should be CST on #{d}"
      assert_equal(-6 * 3600, offset_of(tz, d))
    end
  end

  def test_mississippi_from_1967_uniform_act_defers_to_iana
    assert_nil TzHistory.for(lat: 32.3642, lon: -88.7036, date: "1968-07-15")
  end

  # --- Montana: MT #1 (68%) + MT #9 (22%) = 90% kept MST, no DST, until 1967 ---
  # Crop-verified (PDF 314): MT #1 and MT #9 are pure MST with no peacetime daylight saving
  # 1919-1967 (war excepted; MT #9 differs only pre-1895 = Pacific), while IANA America/Denver
  # applies MDT. The ~10% metro DST tables (MT #2/#3/#10, postwar MDT from 1946) defer, so it
  # is a town-level split (not a flat override that would over-correct the metros).
  def test_rural_montana_no_dst_towns_are_fixed_mst_not_iana_mdt
    [[47.0536, -109.4158], [47.1053, -104.7119], [45.2164, -112.6367]].each do |lat, lon| # Lewistown/Glendive/Dillon
      %w[1930-07-15 1950-07-15 1960-07-15].each do |d|
        tz = TzHistory.for(lat: lat, lon: lon, date: d)
        assert_equal "Etc/GMT+7", tz.identifier, "MT no-DST town at #{lat},#{lon} should be MST on #{d}"
        assert_equal(-7 * 3600, offset_of(tz, d))
      end
    end
  end

  def test_montana_dst_metro_town_defers_to_iana
    # Finlen (Butte/Silver Bow area, MT #10) observed postwar MDT -> defers to IANA.
    assert_nil TzHistory.for(lat: 46.0383, lon: -112.7903, date: "1950-07-15")
  end

  def test_montana_from_1967_uniform_act_defers_to_iana
    assert_nil TzHistory.for(lat: 47.0536, lon: -109.4158, date: "1968-07-15")
  end

  # --- Nevada: Pacific majority is IANA-ok; eastern towns were MOUNTAIN, not Pacific ---
  # Crop-verified (PDF 325): NV #1 (77%) is Pacific (PST->PDT from 1948) = America/Los_Angeles,
  # no residual. The sparsely-populated eastern tables observed MST while IANA models all of
  # Nevada as Pacific -- a 1 h zone divergence. NV #3 = MST throughout; NV #2 = Pacific until
  # 1930 then MST; NV #4 = MST 1930-1965 then back to Pacific. Non-overlapping Mountain windows.
  def test_nevada_pacific_majority_defers_to_iana
    assert_nil TzHistory.for(lat: 40.5789, lon: -118.3042, date: "1930-01-15") # NV #1 (Pacific)
  end

  def test_eastern_nevada_always_mountain_town_is_mst
    # NV #3 (far east, near Utah) was Mountain the whole time -> MST where IANA says Pacific.
    [%w[1925-01-15], %w[1950-01-15], %w[1966-01-15]].each do |d,|
      tz = TzHistory.for(lat: 37.3144, lon: -114.4897, date: d) # NV #3
      assert_equal "Etc/GMT+7", tz.identifier, "eastern NV should be MST on #{d}"
      assert_equal(-7 * 3600, offset_of(tz, d))
    end
  end

  def test_eastern_nevada_switched_to_mountain_in_1930
    # NV #2: Pacific (defer) before 1930, Mountain (MST) after.
    assert_nil TzHistory.for(lat: 41.7261, lon: -115.8964, date: "1925-01-15")
    assert_equal "Etc/GMT+7", TzHistory.for(lat: 41.7261, lon: -115.8964, date: "1950-01-15").identifier
  end

  def test_nevada_nv4_reverted_to_pacific_after_1965
    # NV #4 was Mountain 1930-1965, then back to Pacific -> defers again from 1965.
    assert_equal "Etc/GMT+7", TzHistory.for(lat: 39.6533, lon: -114.8017, date: "1950-01-15").identifier
    assert_nil TzHistory.for(lat: 39.6533, lon: -114.8017, date: "1966-01-15")
  end

  # --- New Hampshire: rural EST kept until 1937 (seaboard pattern, like Maine/CT/DE) ---
  # Crop-verified (PDF 328): no NH table observed DST before 1931; the rural NH #1 (67%)
  # kept EST until 1937, while urban tables adopted DST 1931-1936 and IANA America/New_York
  # applies continuous NYC DST from 1920. Two windows: all towns EST 1919-1931; then only
  # NH #1 EST 1931-1937 (urban towns defer -- they had EDT, which IANA models).
  def test_all_new_hampshire_is_est_before_1931
    # Even an urban NH #2 town was EST before its 1931 DST adoption.
    tz = TzHistory.for(lat: 42.8617, lon: -71.2172, date: "1925-07-15") # NH #2 town (urban)
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1925-07-15"))
  end

  def test_rural_new_hampshire_kept_est_until_1937
    # Conway (NH #1): EST through 1935, then DST from 1937 -> defers.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 44.0536, lon: -71.1289, date: "1935-07-15").identifier
    assert_nil TzHistory.for(lat: 44.0536, lon: -71.1289, date: "1938-07-15")
  end

  def test_urban_new_hampshire_defers_after_its_1931_dst_adoption
    # NH #2 town observed EDT from 1931 -> defers to IANA in 1935 (not EST).
    assert_nil TzHistory.for(lat: 42.8617, lon: -71.2172, date: "1935-07-15")
  end

  # --- New Jersey: urban continuous-DST = IANA; rural tables kept EST at staggered years ---
  # Crop-verified (PDF 333): NJ #1/#6/#9/#11 (urban) had continuous DST from 1920 = IANA, no
  # residual. Rural tables kept EST until adopting US DST: NJ #2 -> 1921, NJ #17 -> 1931,
  # NJ #12 -> 1937 (while IANA applies NYC DST from 1920). Non-overlapping adoption windows.
  def test_nj_urban_continuous_dst_defers_to_iana
    assert_nil TzHistory.for(lat: 40.75, lon: -74.2167, date: "1925-07-15") # NJ #1
  end

  def test_nj_rural_tables_kept_est_until_their_adoption_year
    # NJ #17 (adopt 1931): EST in 1925, defers (had EDT) from 1931.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 39.9069, lon: -74.7886, date: "1925-07-15").identifier
    assert_nil TzHistory.for(lat: 39.9069, lon: -74.7886, date: "1935-07-15")
    # NJ #12 (adopt 1937): still EST in 1935.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 39.9092, lon: -74.1553, date: "1935-07-15").identifier
    assert_nil TzHistory.for(lat: 39.9092, lon: -74.1553, date: "1938-07-15")
  end

  def test_nj_early_adopter_only_diverges_in_1920
    # NJ #2 (adopt 1921): EST only in the 1920 summer, then defers.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 39.6944, lon: -74.8417, date: "1920-07-15").identifier
    assert_nil TzHistory.for(lat: 39.6944, lon: -74.8417, date: "1925-07-15")
  end

  # --- New Mexico: pure MST, no peacetime DST until 1967 (flat Mountain override) ---
  # Crop-verified (PDF 345): NM #1 (98%) is pure MST with no peacetime daylight saving
  # 1883-1967 (war excepted); NM #2/#3 are also MST no-DST. IANA America/Denver applies MDT.
  def test_new_mexico_is_fixed_mst_not_iana_mdt
    [[35.084, -106.65], [35.687, -105.938], [33.394, -104.523]].each do |lat, lon| # ABQ/Santa Fe/Roswell
      %w[1930-07-15 1950-07-15 1960-07-15].each do |d|
        tz = TzHistory.for(lat: lat, lon: lon, date: d)
        assert_equal "Etc/GMT+7", tz.identifier, "NM at #{lat},#{lon} should be MST on #{d}"
        assert_equal(-7 * 3600, offset_of(tz, d))
      end
    end
  end

  def test_new_mexico_from_1967_uniform_act_defers_to_iana
    assert_nil TzHistory.for(lat: 35.084, lon: -106.65, date: "1968-07-15")
  end

  # --- Kansas: dominant Central kept CST 1920-1966; far-west Mountain deferred ---
  # KS #1 (bulk of the state) is straight CST with no local DST until the 1967 Uniform
  # Time Act, while IANA America/Chicago applies continuous summer CDT.

  def test_central_kansas_summer_1950_is_fixed_cst_not_iana_cdt
    tz = TzHistory.for(lat: 37.6872, lon: -97.3301, date: "1950-07-15") # Wichita
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1950-07-15")) # CST, not CDT
  end

  def test_central_kansas_prewar_1930_is_fixed_cst
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 37.6872, lon: -97.3301, date: "1930-07-15").identifier
  end

  def test_kansas_after_1967_uniform_defers_to_iana
    assert_nil TzHistory.for(lat: 37.6872, lon: -97.3301, date: "1968-07-15")
  end

  # --- Louisiana: statewide CST, except New Orleans' one-summer 1946 CDT ---
  # LA #1 (nearly all parishes) is pure CST; LA #2 (Orleans/Jefferson/St. Bernard)
  # differs only by observing CDT in summer 1946, which IANA America/Chicago models.

  def test_new_orleans_summer_1946_defers_to_iana_for_its_cdt
    # Orleans Parish: the exclusion guard blocks the CST override so 1946 CDT resolves.
    assert_nil TzHistory.for(lat: 29.9511, lon: -90.0715, date: "1946-07-15")
  end

  def test_new_orleans_winter_1946_is_the_cst_override
    tz = TzHistory.for(lat: 29.9511, lon: -90.0715, date: "1946-02-15")
    assert_equal "Etc/GMT+6", tz.identifier
  end

  def test_new_orleans_other_years_stay_on_the_cst_override
    # 1950 summer: LA #2 was back on CST (only 1946 had CDT), so override applies.
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 29.9511, lon: -90.0715, date: "1950-07-15").identifier
  end

  def test_rest_of_louisiana_summer_1946_is_fixed_cst
    # Baton Rouge (LA #1): kept CST in 1946; the New Orleans guard does not apply.
    tz = TzHistory.for(lat: 30.4515, lon: -91.1871, date: "1946-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1946-07-15"))
  end

  # --- non-matches ---

  def test_returns_nil_outside_any_polygon
    assert_nil TzHistory.for(lat: 51.5074, lon: -0.1278, date: "1946-01-15") # London
  end

  def test_returns_nil_for_a_modern_birth
    assert_nil TzHistory.for(lat: 35.9606, lon: -83.9207, date: "1990-01-15")
  end

  def test_returns_nil_when_date_missing
    assert_nil TzHistory.for(lat: 35.9606, lon: -83.9207, date: nil)
  end

  # Louisville (Jefferson Co.) is an exclusion guard: IANA already models its real
  # 1921/1941 DST, so we defer to IANA (return nil) rather than substitute.
  def test_louisville_defers_to_iana
    assert_nil TzHistory.for(lat: 38.2527, lon: -85.7585, date: "1921-06-15")
  end

  # --- notes ---

  def test_note_prompts_verification_for_a_shanks_region
    note = TzHistory.note(lat: 39.0837, lon: -84.5086, date: "1923-07-15")
    assert_match(/verify the birth record/i, note)
    assert_match(/Shanks/i, note)
  end

  def test_note_is_nil_for_a_modern_birth
    assert_nil TzHistory.note(lat: 35.9606, lon: -83.9207, date: "1990-01-15")
  end

  # --- New York rural-EST cohort nest (tt PDF 352-359, tables NY#1-226) ---
  # IANA America/New_York applies NYC's continuous EDT every summer from 1920, but most of
  # upstate NY kept EST for years, adopting daylight saving only at staggered dates. The
  # dominant rural table NY#226 (967 towns) stayed EST through 1954. Summer 1920 was daylight
  # statewide and the war years were EWT (both == IANA), so only 1921-1941 / 1946-onward
  # EST summers are corrected.

  def test_ny_dominant_rural_table_summer_1935_is_est
    # Averys Place (Adirondacks, Shanks NY #226): EST via NY#4, IANA gives NYC EDT.
    tz = TzHistory.for(lat: 43.2942, lon: -74.5550, date: "1935-07-15")
    assert_equal "Etc/GMT+5", tz.identifier
  end

  def test_ny_dominant_rural_table_still_est_postwar_1950
    # NY #226 kept EST post-war until adopting DST in 1955.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 43.2942, lon: -74.5550, date: "1950-07-15").identifier
  end

  def test_ny_dominant_rural_table_defers_after_1955_adoption
    assert_nil TzHistory.for(lat: 43.2942, lon: -74.5550, date: "1955-07-15")
  end

  def test_ny_summer_1920_defers_statewide_daylight
    # Every NY table observed EDT in summer 1920 (statewide law) = IANA -> defer.
    assert_nil TzHistory.for(lat: 43.2942, lon: -74.5550, date: "1920-07-15")
  end

  def test_ny_war_years_defer_to_iana_ewt
    # 1942-45 the towns ran EWT (-4) == IANA -> defer, never forced to EST.
    assert_nil TzHistory.for(lat: 43.2942, lon: -74.5550, date: "1943-07-15")
  end

  def test_nyc_metro_continuous_dst_defers_to_iana
    # Babylon (Suffolk Co., Long Island metro, NY #1) had continuous DST = IANA.
    assert_nil TzHistory.for(lat: 40.6956, lon: -73.3261, date: "1935-07-15")
  end

  def test_ny_early_adopter_table13_est_before_1939
    # Austin (Cayuga Co., NY #13): EST until adopting DST in 1939.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 42.8108, lon: -76.4711, date: "1935-07-15").identifier
  end

  def test_ny_early_adopter_table7_defers_after_1925_adoption
    # Barrytown (Dutchess Co., NY #7): EST until 1925, DST (=IANA) after.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 41.9983, lon: -73.9244, date: "1923-07-15").identifier
    assert_nil TzHistory.for(lat: 41.9983, lon: -73.9244, date: "1930-07-15")
  end

  # --- Missouri postwar CST cohort nest (tt PDF 300-301, tables MO#1-49) ---
  # Pre-war ALL tables were CST no-DST (flat Etc/GMT+6 already ships). Postwar every table
  # was CST from 1946 until it adopted DST at a table-specific year; the dominant rural MO#3
  # (86%) never adopted (CST to 1966), while IANA America/Chicago applies CDT every summer.
  # Replaces the old postwar "warn" with a real correction.
  def test_mo_rural_prewar_is_flat_cst
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 38.5767, lon: -92.1735, date: "1935-07-15").identifier
  end

  def test_mo_dominant_rural_postwar_cst_through_1966
    # MO#3 kept CST every postwar summer until US#1 1967.
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 38.5767, lon: -92.1735, date: "1955-07-15").identifier
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 38.5767, lon: -92.1735, date: "1966-07-15").identifier
    assert_nil TzHistory.for(lat: 38.5767, lon: -92.1735, date: "1968-07-15")
  end

  def test_mo_st_louis_suburb_table40_cst_early_then_defers_after_1963
    # Affton (St Louis Co., MO#40) kept CST until adopting DST in 1963 -- the cohort nest
    # corrects 1955 but must NOT over-correct 1965 (a flat postwar override would).
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 38.551, lon: -90.333, date: "1955-07-15").identifier
    assert_nil TzHistory.for(lat: 38.551, lon: -90.333, date: "1965-07-15")
  end

  def test_mo_st_louis_metro_continuous_dst_defers
    # St Louis city (MO#1) had continuous CDT from 1946 = IANA -> defer.
    assert_nil TzHistory.for(lat: 38.633, lon: -90.25, date: "1955-07-15")
  end

  # --- Nebraska two-zone standard time (tt PDF 319, tables NE#1-6) ---
  # NE#1 (71%) = Central CST no-DST; NE#2/#3/#5/#6 = western Mountain MST no-DST. The old
  # flat statewide CST override bled Etc/GMT+6 onto the Mountain transition-belt towns
  # (NE#3 etc.) -- fixed with a town-level split (Central->CST, Mountain->MST).
  def test_ne_central_is_cst
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 41.25, lon: -95.9667, date: "1935-07-15").identifier
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 41.25, lon: -95.9667, date: "1955-07-15").identifier
  end

  def test_ne_mountain_transition_town_is_mst_not_cst
    # Calamus (NE#3, ~lon -99.8): Shanks Mountain (MST); the old flat CST override wrongly
    # read it Etc/GMT+6. Must now be Etc/GMT+7 (MST), not CST.
    assert_equal "Etc/GMT+7", TzHistory.for(lat: 42.1833, lon: -99.75, date: "1935-07-15").identifier
    assert_equal "Etc/GMT+7", TzHistory.for(lat: 42.1833, lon: -99.75, date: "1955-07-15").identifier
  end

  def test_ne_far_west_defers_to_iana_denver
    # Bushnell (NE#2 panhandle): IANA America/Denver was itself MST no-DST here -> defer.
    assert_nil TzHistory.for(lat: 41.2322, lon: -103.8914, date: "1935-07-15")
  end

  # --- North Carolina: VERIFY-ONLY (tt PDF 387) ---
  # NC#1 (2652 towns, 97.6%) = pure EST no-DST 1883, adopting US#1 daylight in 1966 (a year
  # before the federal act), while IANA America/New_York applies EDT every summer. The shipped
  # flat Etc/GMT+5 override (pre-war + postwar ending exactly 1966-04-24) is confirmed correct.
  def test_nc_rural_est_prewar_and_postwar
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 36.4103, lon: -76.7992, date: "1935-07-15").identifier
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 36.4103, lon: -76.7992, date: "1955-07-15").identifier
  end

  def test_nc_defers_after_1966_us_adoption
    # NC#1 adopted US#1 daylight on 1966-04-24 -> matches IANA, override window ends there.
    assert_nil TzHistory.for(lat: 36.4103, lon: -76.7992, date: "1966-07-15")
  end

  # --- North Dakota two-zone town split (tt PDF 405, tables ND#1-10) ---
  # ND#1 (305 towns, 76%) = pure CST no-DST to 1967; ND#9 (71) = pure MST no-DST (western).
  # Fixes: the old flat override warned 1957-1960 (under-correcting pure ND#1) and bled CST
  # onto Mountain ND#9 towns. Town-level split: Central->CST, Mountain->MST.
  def test_nd_central_pure_cst_through_the_1957_60_experiment
    # Everest (ND#1): CST every year incl. the 1957-1960 daylight experiment (was a warn).
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 46.8597, lon: -97.2208, date: "1935-07-15").identifier
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 46.8597, lon: -97.2208, date: "1958-07-15").identifier
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 46.8597, lon: -97.2208, date: "1963-07-15").identifier
  end

  def test_nd_western_mountain_town_is_mst_not_cst
    # Western ND (ND#9) = MST no-DST; the old flat CST override bled Etc/GMT+6 onto it.
    assert_equal "Etc/GMT+7", TzHistory.for(lat: 47.9206, lon: -104.0306, date: "1935-07-15").identifier
  end

  # --- Ohio two-zone town split (tt PDF 409-413, a 5-page span; tables OH#1-118) ---
  # WESTERN Ohio kept CENTRAL time (CST, no DST) until it switched to Eastern in the mid-1920s,
  # then EST no-DST until 1967 (dominant rural OH#34, 1177 towns, switched 1927-04-03). CENTRAL/
  # SE + NE Ohio switched to EST in 1919 and kept EST no-DST until a postwar adoption year.
  # Big-city DST tables defer to IANA. This replaced the buggy flat-EST override (which rendered
  # western Ohio's pre-1927 Central as Eastern) + the postwar warn. Coords are Sidney (Shelby,
  # western OH#34-region), Lancaster (Fairfield, eastern), Ravenna (Portage, NE adopts 1956).
  def test_western_ohio_is_central_cst_before_the_1927_switch
    # Sidney: CST (-6), NOT Eastern -- IANA America/New_York applies EST/EDT (1-2 h fast).
    tz = TzHistory.for(lat: 40.2842, lon: -84.1552, date: "1925-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1925-07-15"))
  end

  def test_western_ohio_is_est_no_dst_after_the_1927_switch
    # Sidney: after the 1927 switch to Eastern, EST with no summer DST (IANA applies EDT).
    tz = TzHistory.for(lat: 40.2842, lon: -84.1552, date: "1935-07-15")
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1935-07-15"))
    # ...still EST no-DST postwar, until US#1 1967.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 40.2842, lon: -84.1552, date: "1960-07-15").identifier
  end

  def test_eastern_ohio_is_est_no_dst_until_1967
    # Lancaster (Fairfield, OH#27): EST no-DST 1919->1967 while IANA applies EDT every summer.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 39.7137, lon: -82.5993, date: "1930-07-15").identifier
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 39.7137, lon: -82.5993, date: "1966-07-15").identifier
    assert_nil TzHistory.for(lat: 39.7137, lon: -82.5993, date: "1968-07-15") # post US#1 -> IANA
  end

  def test_northeast_ohio_adopts_dst_1956_then_defers
    # Ravenna (Portage, OH#67): EST no-DST until the 1956 US#5 adoption, then matches IANA.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 41.1578, lon: -81.2412, date: "1950-07-15").identifier
    assert_nil TzHistory.for(lat: 41.1578, lon: -81.2412, date: "1960-07-15")
  end

  def test_cleveland_metro_defers_to_iana
    # Big-city DST tables (Cleveland/OH#26) observed DST that IANA models -> defer, no override.
    assert_nil TzHistory.for(lat: 41.4993, lon: -81.6944, date: "1935-07-15")
  end

  def test_cincinnati_is_central_until_1927
    # SW Ohio / Cincinnati kept Central time until 1927 (pre-existing metro override, feat[110]).
    assert_equal "America/Chicago", TzHistory.for(lat: 39.1031, lon: -84.5120, date: "1925-07-15").identifier
  end

  def test_ohio_war_years_defer_to_iana
    # 1942-1945 Ohio observed war time (EWT/CWT) = IANA -> the split omits the war window.
    assert_nil TzHistory.for(lat: 40.2842, lon: -84.1552, date: "1943-07-15")
  end

  # --- Oklahoma verify-only (tt PDF 432, single-tt span; tables OK#1-4) ---
  # OK#1 (854 towns, 96.5%) = pure CST, no peacetime DST 1883 -> US#1 1967 (like Mississippi).
  # The pre-existing flat Etc/GMT+6 override (pre-war 1919-10-26..1942-02-09 + postwar
  # 1945-09-30..1967-04-30) is confirmed correct. Panhandle OK#4 (MST until 1921) + NE-corner
  # OK#2/#3 (late CDT) are minor residuals -> DEFERRED.md.
  def test_oklahoma_dominant_is_fixed_cst_no_dst
    # Oklahoma City: CST (-6) all summer while IANA America/Chicago applies CDT.
    tz = TzHistory.for(lat: 35.4676, lon: -97.5164, date: "1930-07-15")
    assert_equal "Etc/GMT+6", tz.identifier
    assert_equal(-6 * 3600, offset_of(tz, "1930-07-15"))
  end

  def test_oklahoma_cst_holds_until_1967_us_adoption
    # Tulsa: still CST no-DST in 1966 (US#1 adoption is 1967-04-30).
    assert_equal "Etc/GMT+6", TzHistory.for(lat: 36.1540, lon: -95.9928, date: "1966-07-15").identifier
    assert_nil TzHistory.for(lat: 36.1540, lon: -95.9928, date: "1968-07-15") # post US#1 -> IANA
  end

  # --- Oregon Pacific no-DST 1953-1960 (tt PDF 439, tables OR#1-17) ---
  # Oregon had no state DST law 1949-1962; in the 1953-1960 decade EVERY Oregon table
  # (rural OR#2 and urban Portland OR#12) kept PST, while IANA America/Los_Angeles applies
  # California's PDT every summer. Flat Etc/GMT+8 over the 35 Pacific counties for that
  # window; Malheur (OR#1, Mountain) and the messy edge summers defer -> DEFERRED.md.
  def test_oregon_pacific_is_pst_no_dst_1953_1960
    # Portland: PST (-8) all summer while IANA America/Los_Angeles applies PDT (-7).
    tz = TzHistory.for(lat: 45.5152, lon: -122.6784, date: "1955-07-15")
    assert_equal "Etc/GMT+8", tz.identifier
    assert_equal(-8 * 3600, offset_of(tz, "1955-07-15"))
    assert_equal "Etc/GMT+8", TzHistory.for(lat: 44.0521, lon: -123.0868, date: "1960-07-15").identifier # Eugene
  end

  def test_oregon_edge_years_and_malheur_defer
    assert_nil TzHistory.for(lat: 45.5152, lon: -122.6784, date: "1948-07-15") # Portland had DST 1948
    assert_nil TzHistory.for(lat: 45.5152, lon: -122.6784, date: "1962-07-15") # DST resumed by 1962
    assert_nil TzHistory.for(lat: 44.0266, lon: -116.9629, date: "1955-07-15") # Malheur = Mountain
  end

  # --- Pennsylvania pre-war rural EST no-DST (tt PDF 448-452, a 5-page span; tables PA#1-123) ---
  # PA is Eastern; rural PA kept EST with no daylight saving while IANA America/New_York applies
  # EDT every summer. Crop-verified dominant rural tables PA#1 (1445 towns; EST no-DST to US#2
  # 1945) and PA#6 (1058 towns; EST no-DST to US#2 1965) -> Etc/GMT+5 for the pre-war window.
  # The DST cities (Philadelphia PA#9, Pittsburgh PA#114, etc.) are on their own tables and
  # defer. Postwar + the other tables are a documented follow-up (tt OCR unreliable) -> DEFERRED.
  def test_pennsylvania_rural_is_est_no_dst_prewar
    # PA#1 rural (Columbia Co.): EST (-5) all summer while IANA applies EDT (-4).
    tz = TzHistory.for(lat: 41.0322, lon: -76.3083, date: "1930-07-15")
    assert_equal "Etc/GMT+5", tz.identifier
    assert_equal(-5 * 3600, offset_of(tz, "1930-07-15"))
    # PA#6 rural (western PA): also EST no-DST pre-war.
    assert_equal "Etc/GMT+5", TzHistory.for(lat: 40.8547, lon: -80.4572, date: "1930-07-15").identifier
  end

  def test_pennsylvania_dst_cities_and_war_defer
    assert_nil TzHistory.for(lat: 39.9526, lon: -75.1652, date: "1930-07-15") # Philadelphia (PA#9) had DST
    assert_nil TzHistory.for(lat: 40.4406, lon: -79.9959, date: "1930-07-15") # Pittsburgh (PA#114) had DST
    assert_nil TzHistory.for(lat: 41.0322, lon: -76.3083, date: "1943-07-15") # war time = IANA
    assert_nil TzHistory.for(lat: 41.0322, lon: -76.3083, date: "1950-07-15") # postwar deferred (follow-up)
  end
end
