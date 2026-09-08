# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.test_files = FileList["test/**/*_test.rb"]
  t.warning = false
end

desc "Compile data/shanks/*.zic into committed TZif blobs via zic"
task :"shanks:build" do
  ruby "tasks/build_shanks_zoneinfo.rb"
end

task default: :test
