require "rubygems"
require "rake"

Gem::Specification.new do |s|
  s.name = "savon"
  s.version = "0.7.7"
  s.date = "2010-03-29"

  s.authors = "Daniel Harrington"
  s.email = "me@rubiii.com"
  s.homepage = "http://github.com/rubiii/savon"
  s.summary = "Heavy metal Ruby SOAP client library"

  s.files = FileList["[A-Z]*", "{lib,spec}/**/*.{rb,xml}"]
  s.test_files = FileList["spec/**/*.rb"]

  s.extra_rdoc_files = ["README.rdoc"]
  s.rdoc_options  = ["--charset=UTF-8", "--line-numbers", "--inline-source"]
  s.rdoc_options += ["--title", "Savon - Heavy metal Ruby SOAP client library"]

  s.add_dependency "builder", ">= 2.1.2"
  s.add_dependency "crack", ">= 0.1.4"
  s.add_dependency "ntlm-http", ">= 0.1.1"

  s.add_development_dependency "rspec", ">= 1.2.8"
  s.add_development_dependency "mocha", ">= 0.9.7"
  s.add_development_dependency "fakeweb", ">= 1.2.7"
end

