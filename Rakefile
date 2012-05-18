require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new

# http://stackoverflow.com/q/5771758/279024
task :require_ruby_18 do
  raise "This must be run on Ruby 1.8" unless RUBY_VERSION =~ /^1\.8/
end
task :release => [:require_ruby_18]

task :default => :spec
task :test => :spec
