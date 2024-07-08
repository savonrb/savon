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
  s.description = s.summary
  s.required_ruby_version = '>= 3.0.0'

  s.license = 'MIT'

  s.add_dependency "nori",     "~> 2.4"
  s.add_dependency "faraday",  "~> 2.8"
  s.add_dependency "faraday-gzip",  "~> 2.0"
  s.add_dependency "faraday-follow_redirects",  "~> 0.3"
  s.add_dependency "wasabi", " > 5"
  s.add_dependency "akami",    "~> 1.2"
  s.add_dependency "gyoku",    "~> 1.2"
  s.add_dependency "builder",  ">= 2.1.2"
  s.add_dependency "nokogiri", ">= 1.8.1"
  s.add_dependency "mail",     "~> 2.5"

  s.add_development_dependency "faraday-net_http_persistent",  "~> 2.1"
  s.add_development_dependency "rubyntlm",  ">= 0.6"
  s.add_development_dependency "rack", " < 4"
  s.add_development_dependency "puma",  ">= 4.3.8", "< 7"

  s.add_development_dependency "byebug"
  s.add_development_dependency "rake",  ">= 12.3.3"
  s.add_development_dependency "rspec", "~> 3.9"
  s.add_development_dependency "mocha", "~> 0.14"
  s.add_development_dependency "json",  ">= 2.3.0"

  s.metadata["rubygems_mfa_required"] = "true"

  s.files = Dir['CHANGELOG.md', 'LICENSE', 'README.md', 'Rakefile', 'lib/**/*.rb']

  s.require_path = "lib"
end
