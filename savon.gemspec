# -*- encoding : utf-8 -*-
lib = File.expand_path("../lib", __FILE__)
$:.unshift lib unless $:.include? lib

require "savon/version"

Gem::Specification.new do |s|
  s.name        = "savon"
  s.version     = Savon::VERSION
  s.authors     = "Daniel Harrington"
  s.email       = "me@rubiii.com"
  s.homepage    = "http://savonrb.com"
  s.summary     = "Heavy metal SOAP client"
  s.description = "Delicious SOAP for the Ruby community"

  s.rubyforge_project = s.name

  s.add_dependency "nori",     "~> 1.1.0"
  s.add_dependency "httpi",    "~> 1.1.0"
  s.add_dependency "wasabi",   "~> 2.5.0"
  s.add_dependency "akami",    "~> 1.2.0"
  s.add_dependency "gyoku",    "~> 0.4.5"

  s.add_dependency "builder",  ">= 2.1.2"
  s.add_dependency "nokogiri", ">= 1.4.0"

  s.add_development_dependency "rake",    "~> 0.9"
  s.add_development_dependency "rspec",   "~> 2.10"
  s.add_development_dependency "mocha",   "~> 0.11"
  s.add_development_dependency "timecop", "~> 0.3"

  s.files = `git ls-files`.split("\n")
  s.require_path = "lib"
end
