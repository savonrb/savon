# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/savon/**/*_spec.rb"
end

desc "Run RSpec integration examples"
RSpec::Core::RakeTask.new "spec:integration" do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

desc "Alias for spec task"
task :test => :spec

task :default => :spec
