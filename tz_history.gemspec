# frozen_string_literal: true

require_relative "lib/tz_history/version"

Gem::Specification.new do |spec|
  spec.name = "tz_history"
  spec.version = TzHistory::VERSION
  spec.authors = ["David Lowenfels"]
  spec.summary = "Historical US timezones for pre-1970 births, where IANA only models the modern zone."
  spec.description = <<~DESC
    IANA/Olson only guarantees local time-zone observance since 1970 and assigns
    every coordinate its modern zone. tz_history corrects a documented set of
    pre-1970 US cases -- county-boundary shifts and sub-state daylight-saving
    history the astrology-standard Shanks American Atlas records but IANA omits --
    by point-in-polygon against county lines, returning a TZInfo::Timezone.
  DESC
  spec.homepage = "https://github.com/dfl/tz_history"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir[
    "lib/**/*.rb",
    "data/us_historical_zones.geojson",
    "data/shanks/*.zic",
    "data/shanks/zoneinfo/**/*",
    "README.md",
    "CHANGELOG.md",
    "LICENSE.txt"
  ]
  spec.require_paths = ["lib"]

  spec.add_dependency "tzinfo", ">= 2.0"
  spec.metadata["rubygems_mfa_required"] = "true"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
end
