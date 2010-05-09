lib = File.expand_path "../lib", __FILE__
$:.unshift lib unless $:.include? lib

require "savon/version"

Gem::Specification.new do |s|
  s.name = "savon"
  s.version = Savon::Version
  s.date = Date.today.to_s

  s.authors = "Daniel Harrington"
  s.email = "me@rubiii.com"
  s.homepage = "http://github.com/rubiii/savon"
  s.summary = "Heavy metal Ruby SOAP client library"

  s.files = Dir["[A-Z]*", "{lib,spec}/**/*.{rb,xml,gz}"]
  s.test_files = Dir["spec/**/*.rb"]

  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options  = ["--charset=UTF-8", "--line-numbers", "--inline-source"]
  s.rdoc_options += ["--title", "Savon - Heavy metal Ruby SOAP client library"]

  s.add_dependency "builder", ">= 2.1.2"
  s.add_dependency "crack", ">= 0.1.4"

  s.add_development_dependency "rspec", ">= 1.2.8"
  s.add_development_dependency "mocha", ">= 0.9.7"
  s.add_development_dependency "fakeweb", ">= 1.2.7"
end