require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new

desc 'Generate a dependency graph'
task :graph do
  system <<-BASH
    rm -rf graph
    mkdir graph
    GRAPH=true rspec
    mv rubydeps.dump graph
    cd graph
    rubydeps --path_filter='lib/savon'
    dot -Tsvg rubydeps.dot > rubydeps.svg
    open -a 'Google Chrome' rubydeps.svg
  BASH
end

task default: :spec
task test: :spec
