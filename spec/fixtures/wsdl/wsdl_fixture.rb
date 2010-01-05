require "yaml"
require "erb"

class WSDLFixture

  # Returns a WSDL document matching a given +method+ name when called without
  # arguments. Otherwise returns the expected value for a given +method+ name
  # matching a fixture.
  def self.method_missing(method, *args)
    return wsdl(method) unless args.first
    expectations[method][args.first]
  end

private

  @@expectations = nil

  # Returns a Hash of expected namespace URI's and SOAP operations loaded
  # from wsdl_fixture.yml.
  def self.expectations
    return @@expectations if @@expectations

    file = File.read File.dirname(__FILE__) + "/wsdl_fixture.yml"
    @@expectations = YAML.load ERB.new(file).result
  end

  @@wsdl = {}

  # Returns the WSDL document by a given file name.
  def self.wsdl(wsdl)
    return @@wsdl[wsdl] if @@wsdl[wsdl]

    file = File.read File.dirname(__FILE__) + "/xml/#{wsdl}.xml"
    @@wsdl[wsdl] = file
  end

end
