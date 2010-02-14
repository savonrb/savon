require "rake"
require "spec/rake/spectask"
require "spec/rake/verify_rcov"
require "rake/rdoctask"

task :default => :spec_verify

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

desc "" # make this task invisible for "rake -T"
Spec::Rake::SpecTask.new(:run_integration_spec) do |spec|
  spec.spec_files = FileList["spec/{integration}/**/*_spec.rb"]
  spec.spec_opts << "--color"
  spec.libs += ["lib", "spec"]
end

Rake::RDocTask.new do |rdoc|
  rdoc.title = "Savon"
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files.include("lib/**/*.rb")
  rdoc.options = ["--line-numbers", "--inline-source"]
end
