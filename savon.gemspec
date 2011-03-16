lib = File.expand_path("../lib", __FILE__)
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

  s.add_dependency "builder", ">= 2.1.2"
  s.add_dependency "crack", "~> 0.1.8"
  s.add_dependency "httpi", ">= 0.7.8"
  s.add_dependency "gyoku", ">= 0.3.0"

  # I'd rather use libxml2. Maybe through nokogiri (not yet available) or
  # libxml-ruby (also not yet available).
  #
  # This might be an option:
  # http://rubygems.org/gems/coupa-libxml-ruby
  # (see http://stackoverflow.com/questions/3038757/canonicalizing-xml-in-ruby)
  #
  # XMLCanonicalizer did not work for me. See notes in
  # lib/savon/wsse/canonicalizer.rb for more information.
  # s.add_dependency "XMLCanonicalizer", "~> 1.0.1"

  s.add_development_dependency "rspec", "~> 2.4.0"
  s.add_development_dependency "autotest"
  s.add_development_dependency "mocha", "~> 0.9.8"
  s.add_development_dependency "timecop", "~> 0.3.5"

  s.files = `git ls-files`.split("\n")
  s.require_path = "lib"
end
