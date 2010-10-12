lib = File.expand_path "../lib", __FILE__
$:.unshift lib unless $:.include? lib

require "savon/version"

Gem::Specification.new do |s|
  s.name = "savon"
  s.version = Savon::Version
  s.authors = "Daniel Harrington"
  s.email = "me@rubiii.com"
  s.homepage = "http://github.com/rubiii/#{s.name}"
  s.summary = "Heavy metal Ruby SOAP client"
  s.description = "Savon is the heavy metal Ruby SOAP client."

  s.rubyforge_project = s.name

  s.add_dependency "builder", "~> 2.1.2"
  s.add_dependency "crack", "~> 0.1.8"
  s.add_dependency "httpi", ">= 0.5.0"

  s.add_development_dependency "rspec", "~> 2.0.0"
  s.add_development_dependency "mocha", "~> 0.9.7"

  s.files = `git ls-files`.split("\n")
  s.require_path = "lib"
end
