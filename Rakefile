require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new do |t|
  t.pattern = "spec/savon/**/*_spec.rb"
end

desc "Run RSpec integration examples"
RSpec::Core::RakeTask.new "spec:integration" do |t|
  t.pattern = "spec/integration/**/*_spec.rb"
end

task :default => :spec
task :test => :spec
