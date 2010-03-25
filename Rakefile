require "rake"
require "spec/rake/spectask"
require "spec/rake/verify_rcov"

task :default => :spec

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList["spec/{savon}/**/*_spec.rb"]
  spec.spec_opts << "--color"
  spec.libs += ["lib", "spec"]
  spec.rcov = true
end

RCov::VerifyTask.new(:spec_verify => :spec) do |verify|
  verify.threshold = 100.0
  verify.index_html = "rcov/index.html"
end

desc "Run integration specs using WEBrick"
task :spec_integration do
  pid = fork { exec "ruby spec/integration/server.rb" }
  sleep 10 # wait until the server is actually ready
  begin
    task(:run_integration_spec).invoke
  ensure
    Process.kill "TERM", pid
    Process.wait pid
  end
end

desc "" # make this task invisible
Spec::Rake::SpecTask.new(:run_integration_spec) do |spec|
  spec.spec_files = FileList["spec/{integration}/**/*_spec.rb"]
  spec.spec_opts << "--color"
  spec.libs += ["lib", "spec"]
end

begin
  require "hanna/rdoctask"

  Rake::RDocTask.new do |rdoc|
    rdoc.title = "Savon - Heavy metal Ruby SOAP client library"
    rdoc.rdoc_dir = "doc"
    rdoc.rdoc_files.include("**/*.rdoc").include("lib/**/*.rb")
    rdoc.options << "--line-numbers"
    rdoc.options << "--webcvs=http://github.com/rubiii/savon/tree/master/"
  end
rescue LoadError
  puts "'gem install hanna' for documentation"
end
