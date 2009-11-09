require "rubygems"
require "rake"
require "spec/rake/spectask"
require "rake/rdoctask"

task :default => :spec

Spec::Rake::SpecTask.new do |spec|
  spec.spec_files = FileList["spec/**/*_spec.rb"]
  spec.spec_opts << "--color"
end

Rake::RDocTask.new do |rdoc|
  rdoc.title = "Savon"
  rdoc.rdoc_dir = "rdoc"
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include("README.rdoc", "lib/**/*.rb")
  rdoc.options = ["--line-numbers", "--inline-source"]
end

begin
  require "jeweler"
  Jeweler::Tasks.new do |spec|
    spec.name = "savon"
    spec.author = "Daniel Harrington"
    spec.email = "me@rubiii.com"
    spec.homepage = "http://github.com/rubiii/savon"
    spec.summary = "SOAP client library to enjoy"
    spec.description = spec.summary

    spec.files = FileList["[A-Z]*", "{lib,spec}/**/*.{rb,xml}"]

    spec.rdoc_options += [
      "--title", "Savon",
      "--main", "README.rdoc",
      "--line-numbers",
      "--inline-source"
    ]

    spec.add_runtime_dependency("cobravsmongoose", "0.0.2")
    spec.add_runtime_dependency("hpricot", "0.8.2")

    spec.add_development_dependency("rspec", ">= 1.2.8")
    spec.add_development_dependency("rr", ">= 0.10.0")
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end
