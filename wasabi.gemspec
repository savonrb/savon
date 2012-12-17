# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "wasabi/version"

Gem::Specification.new do |s|
  s.name        = "wasabi"
  s.version     = Wasabi::VERSION
  s.authors     = ["Daniel Harrington"]
  s.email       = ["me@rubiii.com"]
  s.homepage    = "https://github.com/rubiii/#{s.name}"
  s.summary     = "A simple WSDL parser"
  s.description = s.summary

  s.rubyforge_project = s.name

  s.add_dependency "httpi",    "~> 2.0"
  s.add_dependency "nokogiri", ">= 1.4.0"

  s.add_development_dependency "rake",  "~> 0.9"
  s.add_development_dependency "rspec", "~> 2.10"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
