require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/savon/**/*_spec.rb"
end

desc "Run RSpec integration examples"
RSpec::Core::RakeTask.new "spec:integration" do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

# http://stackoverflow.com/q/5771758/279024
task :require_ruby_18 do
  raise "This must be run on Ruby 1.8" unless RUBY_VERSION =~ /^1\.8/
end
task :release => [:require_ruby_18]

task :default => :spec
task :test => :spec
