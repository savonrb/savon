require "rake"

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new do |t|
    t.spec_opts = %w(-fd -c)
  end
rescue LoadError
  desc message = %{"gem install rspec --pre" to run the specs}
  task(:spec) { abort message }
end

task :default => :spec
