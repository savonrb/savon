require "rubygems"
require "rake"
require "spec/rake/spectask"
require "spec/rake/verify_rcov"
require "rake/rdoctask"

task :default => :spec_verify_rcov

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList["spec/**/*_spec.rb"]
  spec.spec_opts << "--color"
  spec.libs += ["lib", "spec"]
  spec.rcov = true
  spec.rcov_dir = "rcov"
end

RCov::VerifyTask.new(:spec_verify_rcov => :spec) do |verify|
  verify.threshold = 100.0
  verify.index_html = "rcov/index.html"
end

Rake::RDocTask.new do |rdoc|
  rdoc.title = "Savon"
  rdoc.rdoc_dir = "rdoc"
  rdoc.rdoc_files.include("lib/**/*.rb")
  rdoc.options = ["--line-numbers", "--inline-source"]
end
