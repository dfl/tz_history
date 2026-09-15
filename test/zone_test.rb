# frozen_string_literal: true

require "test_helper"

# Cross-check harness for the Shanks TZif engine (docs/EXTRACTION.md §5).
#
# Two regression nets keep bulk extraction safe:
#
#   1. TWINS -- a Shanks table that has a genuine IANA counterpart must reproduce its
#      OBSERVED UTC OFFSET every month across the overlap span. A mismatch is an
#      OCR/transcription bug, not new data. America/Kentucky/Louisville (== KY_69) is
#      the seed; every future table with an IANA twin is added to SHANKS_IANA_TWINS
#      and inherits the same parameterized test for free.
#
#   2. HAND ASSERTIONS -- a table with NO IANA twin (the residual sub-state histories
#      IANA omits: northern KY's 1920-26 summers, Alabama's 1941 summer) can't be
#      cross-checked, so the visual-verified DST seasons are pinned by hand here.
#
# We compare the OBSERVED OFFSET (what actually shifts a chart), never the
# abbreviation: Shanks labels war-time daylight CWT where IANA uses CDT, but -05 is -05.
class ZoneTest < Minitest::Test
  include TestHelpers

  # Shanks table id => the IANA zone it must match, and the span they overlap.
  SHANKS_IANA_TWINS = {
    "KY_69" => { iana: "America/Kentucky/Louisville", from: 1884, to: 1969 }
  }.freeze

  def test_returns_a_tzinfo_timezone_named_for_the_table
    z = TzHistory::Zone.tzinfo("KY_69")
    assert_instance_of TZInfo::DataTimezone, z
    assert_equal "Shanks/KY_69", z.identifier
  end

  def test_returns_nil_for_unknown_table
    assert_nil TzHistory::Zone.tzinfo("ZZ_99")
  end

  def test_memoizes
    assert_same TzHistory::Zone.tzinfo("KY_69"), TzHistory::Zone.tzinfo("KY_69")
  end

  # Parameterized twin cross-check: every Shanks table with an IANA counterpart must
  # match it, offset-for-offset, on the 1st and 15th of every month across the span.
  def test_shanks_tables_match_their_iana_twins_every_month
    SHANKS_IANA_TWINS.each do |table, spec|
      shanks = TzHistory::Zone.tzinfo(table)
      iana = TZInfo::Timezone.get(spec[:iana])
      mismatches = []
      (spec[:from]..spec[:to]).each do |year|
        (1..12).each do |month|
          [1, 15].each do |day|
            probe = Date.new(year, month, day)
            s = offset_of(shanks, probe)
            i = offset_of(iana, probe)
            mismatches << "#{table} #{probe}: shanks #{s} vs #{spec[:iana]} #{i}" if s != i
          end
        end
      end
      assert_empty mismatches, "offset mismatches vs IANA twin:\n#{mismatches.first(20).join("\n")}"
    end
  end

  def test_ky69_matches_louisville_around_every_transition
    shanks = TzHistory::Zone.tzinfo("KY_69")
    iana = TZInfo::Timezone.get("America/Kentucky/Louisville")
    transitions = %w[
      1918-03-31 1918-10-27 1919-03-30 1919-10-26 1921-05-01 1921-09-01
      1941-04-27 1941-09-28 1942-02-09 1945-09-30 1946-04-28 1946-06-02
      1950-04-30 1950-09-24 1961-04-30 1961-07-23 1968-04-28 1968-10-27
      1969-04-27 1969-10-26
    ]
    transitions.each do |iso|
      d = Date.parse(iso)
      [d - 1, d + 1].each do |probe|
        assert_equal offset_of(iana, probe), offset_of(shanks, probe),
                     "offset differs from IANA at #{probe} (around #{iso})"
      end
    end
  end

  # --- hand assertions for tables with NO IANA twin ---

  def test_ky69_resolves_summer_dst_cases_a_fixed_offset_cannot
    shanks = TzHistory::Zone.tzinfo("KY_69")
    assert_equal(-18_000, offset_of(shanks, "1921-06-15")) # CDT summer
    assert_equal(-18_000, offset_of(shanks, "1941-07-01")) # CDT summer
    assert_equal(-21_600, offset_of(shanks, "1930-01-15")) # CST winter
  end

  def test_ky71_northern_kentucky_summers_1920_to_1926
    shanks = TzHistory::Zone.tzinfo("KY_71")
    assert_equal(-18_000, offset_of(shanks, "1923-07-15")) # CDT summer
    assert_equal(-21_600, offset_of(shanks, "1923-01-15")) # CST winter
    assert_equal(-18_000, offset_of(shanks, "1930-07-15")) # Eastern standard after 1926 switch
  end

  # Alabama AL #1: statewide CST with a REAL 1941 summer DST (Jul 21 - Oct 1) that
  # neither the flat Etc/GMT+6 override nor IANA America/Chicago models. No IANA twin,
  # so the visual-verified seasons are pinned here.
  def test_al1_alabama_1941_summer_dst_and_surrounding_standard_time
    shanks = TzHistory::Zone.tzinfo("AL_1")
    assert_equal(-21_600, offset_of(shanks, "1941-01-15")) # CST winter
    assert_equal(-18_000, offset_of(shanks, "1941-08-15")) # CDT -- the 1941 summer residual
    assert_equal(-18_000, offset_of(shanks, "1941-09-30")) # CDT still on the day before fallback
    assert_equal(-21_600, offset_of(shanks, "1941-10-15")) # CST after Oct 1 fallback
    assert_equal(-21_600, offset_of(shanks, "1930-07-15")) # no DST 1920-1940
    assert_equal(-18_000, offset_of(shanks, "1943-07-01")) # CWT war-time daylight
  end

  # Netherlands NL #1 (Amsterdam / whole country) -- the first INTERNATIONAL Atlas table.
  # Amsterdam Mean Time = +0:19:32 (meridian 4E53), the sub-hour offset a flat Etc/GMT
  # zone cannot hold, redefined to exactly +0:20 (meridian 5E00) on 1937-07-01. The
  # DEFAULT IANA Europe/Amsterdam is merely a Link to Europe/Brussels (WET/+0:00) pre-1940,
  # so a plain geographic lookup is wrong for EVERY pre-1940 Dutch birth. IANA keeps the
  # real history only in the opt-in `backzone` file; Shanks/NL_1 reproduces that backzone
  # zone to the second (575/575 mid-months 1892-1940 -- reproduce via research/intl/), but
  # backzone is not in the system tzdata, so the offsets are pinned here by hand.
  def test_nl1_netherlands_amsterdam_mean_time
    shanks = TzHistory::Zone.tzinfo("NL_1")
    assert_equal(1172, offset_of(shanks, "1910-07-15")) # AMT +0:19:32, no summer time yet
    assert_equal(1172, offset_of(shanks, "1900-01-15")) # AMT winter
    assert_equal(4772, offset_of(shanks, "1925-07-15")) # NST = AMT + 1:00 summer (+1:19:32)
    assert_equal(1172, offset_of(shanks, "1935-01-15")) # AMT winter
    assert_equal(4800, offset_of(shanks, "1938-07-15")) # summer on the +0:20 base (+1:20:00)
    assert_equal(1200, offset_of(shanks, "1939-01-15")) # Dutch Time +0:20 exactly
  end

  # Iceland IS #1 (whole country) -- Iceland stood 1 HOUR BEHIND GMT (meridian 15W,
  # -1:00) from 1908, summer time raising the clock to GMT (+00), until permanent GMT
  # in 1968. Before 1908: Reykjavik mean solar time, -1:28. The DEFAULT IANA build LINKS
  # Atlantic/Reykjavik -> Africa/Abidjan (GMT +0), off by a full hour every 1908-1968
  # winter; the real history is Almanak-sourced but only in the opt-in `backzone`.
  # Shanks p.195 is the primary; three Shanks gaps (omitted 1939/1940 summer time,
  # spurious July 1941/1942 fall-backs) are corrected from the sourced Almanak -- the
  # 1940 and 1941 summer assertions below are the regression guards for those fixes.
  def test_is1_iceland_one_hour_behind_gmt
    shanks = TzHistory::Zone.tzinfo("IS_1")
    assert_equal(-5280, offset_of(shanks, "1900-01-15")) # Reykjavik MST -1:28 (pre-1908)
    assert_equal(-3600, offset_of(shanks, "1910-07-15")) # std -1:00, no summer time yet
    assert_equal(-3600, offset_of(shanks, "1925-07-15")) # std -1:00 (no DST 1922-1938)
    assert_equal(0,     offset_of(shanks, "1940-07-15")) # summer +00 (Shanks omitted 1940 DST; Almanak-sourced)
    assert_equal(0,     offset_of(shanks, "1941-08-15")) # summer +00 (Shanks fell back 2/Jul; Almanak keeps it to autumn)
    assert_equal(-3600, offset_of(shanks, "1965-01-15")) # winter std -1:00
    assert_equal(0,     offset_of(shanks, "1965-07-15")) # summer +00
    assert_equal(0,     offset_of(shanks, "1968-07-15")) # permanent GMT from 1968-04-07
  end

  # Luxembourg LU #1 (whole country) -- Luxembourg kept CENTRAL European Time (+1:00,
  # summer +2:00) from 1904, switched to WESTERN European Time (0:00, summer +1:00) in
  # 1918, then back to CET at the 1940 occupation. The DEFAULT IANA build LINKS
  # Europe/Luxembourg -> Europe/Brussels (WET), so it is a full hour low across 1904-1918.
  def test_lu1_luxembourg_cet_then_wet
    shanks = TzHistory::Zone.tzinfo("LU_1")
    assert_equal(3600, offset_of(shanks, "1910-01-15")) # CET +1:00 (default Brussels would say 0)
    assert_equal(7200, offset_of(shanks, "1916-07-15")) # CEST +2:00 (WWI summer time)
    assert_equal(0,    offset_of(shanks, "1925-01-15")) # WET 0:00 (switched 1918)
    assert_equal(3600, offset_of(shanks, "1925-07-15")) # WEST +1:00 summer
    assert_equal(7200, offset_of(shanks, "1941-07-15")) # occupation CEST +2:00 (continuous 1940-1942)
  end

  # Norway NO #1 (whole country) -- uniform CET (+1:00) from 1895, with summer time ONLY
  # in 1916, 1940-1945 and 1959-1965. The DEFAULT IANA build LINKS Europe/Oslo ->
  # Europe/Berlin, whose DST years differ, so it is an hour off in 1917-1918/1945-1949/
  # 1959-1965. The 1917 (no DST) and 1960 (DST) assertions are the divergence guards.
  def test_no1_norway_uniform_cet
    shanks = TzHistory::Zone.tzinfo("NO_1")
    assert_equal(3600, offset_of(shanks, "1910-01-15")) # CET +1:00
    assert_equal(7200, offset_of(shanks, "1916-07-15")) # CEST +2:00 (Norway's 1916 summer time)
    assert_equal(3600, offset_of(shanks, "1917-07-15")) # CET -- NO summer 1917 (Berlin would be +2:00)
    assert_equal(7200, offset_of(shanks, "1943-07-15")) # occupation CEST +2:00
    assert_equal(3600, offset_of(shanks, "1950-07-15")) # CET -- no DST 1946-1958
    assert_equal(7200, offset_of(shanks, "1960-07-15")) # CEST +2:00 (1959-1965 summer time)
  end

  # Denmark DK #1 (whole country) -- Copenhagen Mean Time (+0:50:20) from 1890, CET from
  # 1894, with summer time in 1916 and 1940-1948 (occupation/postwar). The DEFAULT IANA
  # build LINKS Europe/Copenhagen -> Europe/Berlin, whose DST years differ, so it is off
  # in 1917-1918, 1940 and 1945-1949. DK_1 == backzone Copenhagen 960/960 mid-months.
  def test_dk1_denmark_cmt_then_cet
    shanks = TzHistory::Zone.tzinfo("DK_1")
    assert_equal(3020, offset_of(shanks, "1892-01-15")) # Copenhagen MT +0:50:20 (meridian 12E35)
    assert_equal(3600, offset_of(shanks, "1910-01-15")) # CET +1:00 from 1894
    assert_equal(7200, offset_of(shanks, "1916-07-15")) # CEST +2:00 (Denmark's 1916 summer time)
    assert_equal(3600, offset_of(shanks, "1917-07-15")) # CET -- NO summer 1917 (Berlin would be +2:00)
    assert_equal(7200, offset_of(shanks, "1941-07-15")) # occupation CEST +2:00 (continuous 1940-1942)
    assert_equal(3600, offset_of(shanks, "1949-07-15")) # CET -- no Danish DST 1949 (Berlin kept it)
  end

  # Netherlands Antilles ABC islands CW #1 (Aruba + Curacao, Shanks Time Table #3) --
  # -4:30 from 12 Feb 1912, then -4:00 (AST) from 1 Jan 1965. The DEFAULT IANA build
  # LINKS both America/Aruba and America/Curacao to America/Puerto_Rico (-4:00 from 1899,
  # -3:00 Atlantic War Time 1942-1945), so it is 30 min fast across 1912-1965 and 90 min
  # off in 1942-1945. CW_1 == backzone America/Curacao and America/Aruba to the second
  # across the standard era (695/696 mid-months 1912-1969, the sole miss being Jan-1912
  # island LMT, which is out of window).
  def test_cw1_netherlands_antilles_abc_standard
    shanks = TzHistory::Zone.tzinfo("CW_1")
    assert_equal(-16200, offset_of(shanks, "1930-06-15")) # -4:30 standard (67W30)
    assert_equal(-16200, offset_of(shanks, "1943-06-15")) # still -4:30 (default PR = -3:00 AWT)
    assert_equal(-16200, offset_of(shanks, "1964-12-15")) # -4:30 through end of 1964
    assert_equal(-14400, offset_of(shanks, "1965-06-15")) # -4:00 (AST) from 1 Jan 1965
  end

  # Equatorial Guinea GQ #1 (whole country) -- GMT from 1912, WAT (+1:00) from 15 Dec 1963.
  # The DEFAULT IANA build LINKS Africa/Malabo to Africa/Lagos (WAT +1:00 from 1919), so it
  # is a full hour fast across 1919-1963. GQ_1 == backzone Africa/Malabo 696/696 mid-months.
  def test_gq1_equatorial_guinea_gmt
    shanks = TzHistory::Zone.tzinfo("GQ_1")
    assert_equal(0,    offset_of(shanks, "1930-06-15")) # GMT (default Lagos = WAT +1:00)
    assert_equal(0,    offset_of(shanks, "1963-06-15")) # still GMT through most of 1963
    assert_equal(3600, offset_of(shanks, "1964-06-15")) # WAT (+1:00) from 15 Dec 1963
  end

  # Niger NE #1 (Niamey / western division, Shanks Time Table #2) -- -1:00 from 1912, GMT
  # from 26 Feb 1934, WAT (+1:00) from 1960. The DEFAULT IANA build LINKS Africa/Niamey to
  # Africa/Lagos, so it is 1.5-2 h off across 1912-1934 and a full hour off across 1934-1960.
  # NE_1 == backzone Africa/Niamey 696/696 mid-months 1912-1969.
  def test_ne1_niger_niamey
    shanks = TzHistory::Zone.tzinfo("NE_1")
    assert_equal(-3600, offset_of(shanks, "1920-06-15")) # -1:00 (default Lagos = +0:30/WAT)
    assert_equal(0,     offset_of(shanks, "1950-06-15")) # GMT (default Lagos = WAT +1:00)
    assert_equal(3600,  offset_of(shanks, "1961-06-15")) # WAT (+1:00) from 1960
  end

  # Tanzania TZ #1 (mainland / Dar es Salaam, Shanks Time Table #2) -- EAT (+3:00) 1931-1948,
  # +2:45 1948-1961, then EAT again. The DEFAULT IANA build LINKS Africa/Dar_es_Salaam to
  # Africa/Nairobi (+2:30 1936-1942, +3:00 else), so it is 30 min slow across 1937-1942 and
  # 15 min fast across 1948-1961. TZ_1 == backzone Africa/Dar_es_Salaam 468/468 mid-months.
  def test_tz1_tanzania_dar_es_salaam
    shanks = TzHistory::Zone.tzinfo("TZ_1")
    assert_equal(10800, offset_of(shanks, "1940-06-15")) # EAT +3:00 (default Nairobi = +2:30)
    assert_equal(9900,  offset_of(shanks, "1950-06-15")) # +2:45 (default Nairobi = +3:00)
    assert_equal(10800, offset_of(shanks, "1962-06-15")) # EAT +3:00 from 1961
  end

  # --- West-Africa whole-hour cluster (all default-Linked to Africa/Abidjan = GMT) ------

  # Senegal SN #1 (whole country) -- -1:00 from 1912, GMT from 1 Jun 1941. The DEFAULT
  # IANA build LINKS Africa/Dakar to Africa/Abidjan (GMT), so it is a full hour fast
  # across 1912-1941. SN_1 == backzone Africa/Dakar 696/696 mid-months 1912-1969.
  def test_sn1_senegal
    shanks = TzHistory::Zone.tzinfo("SN_1")
    assert_equal(-3600, offset_of(shanks, "1930-06-15")) # -1:00 (default Abidjan = GMT)
    assert_equal(-3600, offset_of(shanks, "1941-01-15")) # still -1:00 early 1941
    assert_equal(0,     offset_of(shanks, "1942-06-15")) # GMT from 1 Jun 1941
  end

  # Guinea GN #1 (whole country) -- GMT 1912-1934, -1:00 1934-1960, then GMT. The DEFAULT
  # IANA build LINKS Africa/Conakry to Africa/Abidjan (GMT), so it is a full hour fast
  # across 1934-1960. GN_1 == backzone Africa/Conakry 696/696 mid-months 1912-1969.
  def test_gn1_guinea
    shanks = TzHistory::Zone.tzinfo("GN_1")
    assert_equal(0,     offset_of(shanks, "1920-06-15")) # GMT phase (matches default)
    assert_equal(-3600, offset_of(shanks, "1950-06-15")) # -1:00 (default Abidjan = GMT)
    assert_equal(0,     offset_of(shanks, "1961-06-15")) # GMT from 1 Jan 1960
  end

  # Mauritania MR #1 (whole country) -- GMT 1912-1934, -1:00 1934-1960, then GMT from
  # 28 Nov 1960. The DEFAULT IANA build LINKS Africa/Nouakchott to Africa/Abidjan (GMT),
  # so it is a full hour fast across 1934-1960. MR_1 == backzone 696/696 mid-months.
  def test_mr1_mauritania
    shanks = TzHistory::Zone.tzinfo("MR_1")
    assert_equal(0,     offset_of(shanks, "1920-06-15")) # GMT phase (matches default)
    assert_equal(-3600, offset_of(shanks, "1950-06-15")) # -1:00 (default Abidjan = GMT)
    assert_equal(0,     offset_of(shanks, "1961-06-15")) # GMT from 28 Nov 1960
  end

  # Mali ML #1 (Bamako / southern division, Shanks Time Table #2) -- GMT 1912-1934,
  # -1:00 1934-1960, then GMT from 20 Jun 1960. IANA models all of Mali as Africa/Bamako
  # (default Linked to Africa/Abidjan = GMT), so it is a full hour fast across 1934-1960.
  # ML_1 == backzone Africa/Bamako 696/696 mid-months 1912-1969.
  def test_ml1_mali_bamako
    shanks = TzHistory::Zone.tzinfo("ML_1")
    assert_equal(0,     offset_of(shanks, "1920-06-15")) # GMT phase (matches default)
    assert_equal(-3600, offset_of(shanks, "1950-06-15")) # -1:00 (default Abidjan = GMT)
    assert_equal(0,     offset_of(shanks, "1961-06-15")) # GMT from 20 Jun 1960
  end

  # The Gambia GM #1 (whole country) -- Banjul Mean Time -1:06:36 (1912-1933), -1:00
  # (1933-1942), then GMT. The DEFAULT IANA build LINKS Africa/Banjul to Africa/Abidjan
  # (GMT), so it is >1 h off across 1912-1933 and a full hour off across 1933-1942. The
  # two transition dates are IANA's ordinance-sourced values (P Chan 2020; Shanks prints
  # 1935/1964). GM_1 == backzone Africa/Banjul 696/696 mid-months 1912-1969.
  def test_gm1_gambia
    shanks = TzHistory::Zone.tzinfo("GM_1")
    assert_equal(-3996, offset_of(shanks, "1920-06-15")) # Banjul Mean Time -1:06:36
    assert_equal(-3600, offset_of(shanks, "1938-06-15")) # -1:00 from 1 Apr 1933
    assert_equal(0,     offset_of(shanks, "1943-06-15")) # GMT from 1 Feb 1942
  end

  # Benin BJ #1 (whole country) -- GMT 1912-1934, then WAT (+1:00) from 26 Feb 1934. The
  # DEFAULT IANA build LINKS Africa/Porto-Novo to Africa/Lagos (WAT +1:00 from 1919), so
  # it is a full hour fast across 1919-1934; tzdb endorses the 1934 date ("go with Shanks
  # & Pottenger"). BJ_1 == backzone Africa/Porto-Novo 696/696 mid-months 1912-1969.
  def test_bj1_benin
    shanks = TzHistory::Zone.tzinfo("BJ_1")
    assert_equal(0,    offset_of(shanks, "1925-06-15")) # GMT (default Lagos = WAT +1:00)
    assert_equal(0,    offset_of(shanks, "1934-01-15")) # still GMT early 1934
    assert_equal(3600, offset_of(shanks, "1935-06-15")) # WAT (+1:00) from 26 Feb 1934
  end

  # --- Central-Africa whole-hour cluster (all default-Linked to Africa/Lagos) ----------

  # Cameroon / CAR / Congo-Brazzaville / Gabon: town LMT until 1/Jan/1912, then WAT
  # (+1:00) forever. IANA links each to Africa/Lagos, which reached WAT only 1 Sep 1919,
  # so the default is 30-47 min slow across 1912-1919. Each == its backzone twin 960/960.
  def test_cm1_cameroon
    shanks = TzHistory::Zone.tzinfo("CM_1")
    assert_equal(2328, offset_of(shanks, "1900-06-15")) # Douala LMT +0:38:48 (pre-1912)
    assert_equal(3600, offset_of(shanks, "1915-06-15")) # WAT +1:00 (default Lagos still +0:30)
  end

  def test_cf1_central_african_republic
    shanks = TzHistory::Zone.tzinfo("CF_1")
    assert_equal(4460, offset_of(shanks, "1900-06-15")) # Bangui LMT +1:14:20 (pre-1912)
    assert_equal(3600, offset_of(shanks, "1915-06-15")) # WAT +1:00
  end

  def test_cg1_congo_brazzaville
    shanks = TzHistory::Zone.tzinfo("CG_1")
    assert_equal(3668, offset_of(shanks, "1900-06-15")) # Brazzaville LMT +1:01:08 (pre-1912)
    assert_equal(3600, offset_of(shanks, "1915-06-15")) # WAT +1:00
  end

  def test_ga1_gabon
    shanks = TzHistory::Zone.tzinfo("GA_1")
    assert_equal(2268, offset_of(shanks, "1900-06-15")) # Libreville LMT +0:37:48 (pre-1912)
    assert_equal(3600, offset_of(shanks, "1915-06-15")) # WAT +1:00
  end

  # Angola AO #1 -- the early standardizer: Luanda Mean Time (+0:52:04) from 1892, then
  # WAT (+1:00) from 26 May 1911. Default Africa/Luanda links to Lagos (LMT/GMT/+0:30 <1919).
  # AO_1 == backzone Africa/Luanda 953/960 (the 7 misses are the Jun-Dec 1911 sub-hour sliver).
  def test_ao1_angola
    shanks = TzHistory::Zone.tzinfo("AO_1")
    assert_equal(3124, offset_of(shanks, "1900-06-15")) # Luanda MT +0:52:04
    assert_equal(3600, offset_of(shanks, "1915-06-15")) # WAT +1:00 from 26 May 1911
  end

  # --- Eastern Caribbean cluster (all default-Linked to America/Puerto_Rico) -----------

  # The Leeward/Windward islands + Trinidad + both Virgin Islands: LMT -> AST (-4:00) at
  # standardization (1911-1912), then flat -4:00 with NO daylight or war time. The DEFAULT
  # IANA build LINKS every one to America/Puerto_Rico, which observed -3:00 Atlantic War
  # Time 1942-1945 -- so the default is a FULL HOUR fast in the war years. Each table ==
  # its backzone twin 960/960 mid-months 1890-1969. The distinguishing assertion is the
  # war-year offset (-4:00, not the default's -3:00), plus the capital LMT before window.
  def test_caribbean_ast_cluster
    {
      "AI_1" => -15136, # Anguilla, The Valley -4:12:16
      "DM_1" => -14736, # Dominica, Roseau -4:05:36
      "GD_1" => -14820, # Grenada, St George's -4:07:00
      "GP_1" => -14768, # Guadeloupe, Pointe-a-Pitre -4:06:08
      "MS_1" => -14932, # Montserrat, Plymouth -4:08:52
      "KN_1" => -15052, # St Kitts, Basseterre -4:10:52
      "LC_1" => -14640, # St Lucia, Castries -4:04:00
      "VC_1" => -14696, # St Vincent, Kingstown -4:04:56
      "TT_1" => -14764, # Trinidad, Port of Spain -4:06:04
      "VI_1" => -15584, # US Virgin, Charlotte Amalie -4:19:44
      "VG_1" => -15508, # British Virgin, Road Town -4:18:28
    }.each do |table, lmt|
      shanks = TzHistory::Zone.tzinfo(table)
      assert_equal(-14400, offset_of(shanks, "1943-06-15"), "#{table} war-year AST -4:00 (default PR = -3:00)")
      assert_equal(-14400, offset_of(shanks, "1925-06-15"), "#{table} AST -4:00")
      assert_equal(lmt,    offset_of(shanks, "1905-06-15"), "#{table} pre-standardization capital LMT")
    end
  end

  # Antigua & Barbuda AG #1 -- the cluster outlier: EST (-5:00) 1912-1951, then AST (-4:00).
  # Default America/Antigua links to Puerto Rico (AST, -3:00 war time), so it is a full hour
  # fast across the whole 1912-1951 EST era and TWO hours off in the war years. AG_1 ==
  # backzone America/Antigua 960/960 mid-months.
  def test_ag1_antigua_est_era
    shanks = TzHistory::Zone.tzinfo("AG_1")
    assert_equal(-18000, offset_of(shanks, "1925-06-15")) # EST -5:00 (default PR = -4:00)
    assert_equal(-18000, offset_of(shanks, "1943-06-15")) # still EST -5:00 (default PR = -3:00 AWT)
    assert_equal(-14400, offset_of(shanks, "1960-06-15")) # AST -4:00 from 1 Jan 1951
  end
end
