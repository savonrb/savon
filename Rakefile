require "rubygems"
require "rake"
require "spec/rake/spectask"
require "rake/rdoctask"

task :default => :spec

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList["spec/**/*_spec.rb"]
  spec.spec_opts << "--color"
  spec.libs << "lib"
  spec.rcov = true
  spec.rcov_dir = "rcov"
end

Rake::RDocTask.new do |rdoc|
  rdoc.title = "Savon"
  rdoc.rdoc_dir = "rdoc"
  rdoc.main = "README.textile"
  rdoc.rdoc_files.include("README.textile", "lib/**/*.rb")
  rdoc.options = ["--line-numbers", "--inline-source"]
end

begin
  require "jeweler"
  Jeweler::Tasks.new do |spec|
    spec.name = "savon"
    spec.author = "Daniel Harrington"
    spec.email = "me@rubiii.com"
    spec.homepage = "http://github.com/rubiii/savon"
    spec.summary = "Heavy metal Ruby SOAP client library"
    spec.description = spec.summary

    spec.files = FileList["[A-Z]*", "{lib,spec}/**/*.{rb,xml}"]

    spec.rdoc_options += [
      "--title", "Savon",
      "--main", "README.textile",
      "--line-numbers",
      "--inline-source"
    ]

    spec.add_runtime_dependency("builder", ">= 2.1.2")
    spec.add_runtime_dependency("crack", ">= 0.1.4")

    spec.add_development_dependency("rspec", ">= 1.2.8")
    spec.add_development_dependency("mocha", ">= 0.9.7")
    spec.add_development_dependency("fakeweb", ">= 1.2.7")
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
