require "rake"

begin
  require "yard"
  
  YARD::Rake::YardocTask.new do |t|
    t.files = ["README.md", "lib/**/*.rb"]
  end
rescue LoadError
  desc message = %{"gem install yard" to generate documentation}
  task("yard") { abort message }
end

begin  
  require "metric_fu"
  
  MetricFu::Configuration.run do |c|
    c.metrics = [:churn, :flog, :flay, :reek, :roodi, :saikuro] # :rcov seems to be broken
    c.graphs = [:flog, :flay, :reek, :roodi]
    c.flay = { :dirs_to_flay => ["lib"], :minimum_score => 20 }
    c.rcov[:rcov_opts] << "-Ilib -Ispec"
  end
rescue LoadError
  desc message = %{"gem install metric_fu" to generate metrics}
  task("metrics:all") { abort message }
end

begin
  require "rspec/core/rake_task"
  
  RSpec::Core::RakeTask.new do |t|
    t.rspec_opts = %w(-fd -c)
  end
rescue LoadError
  desc message = %{"gem install rspec --pre" to run the specs}
  task(:spec) { abort message }
end

task :default => :spec
