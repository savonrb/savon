require "yaml"
require "erb"

class WSDLFixture

  def self.method_missing(method, *args)
    return wsdl(method) unless args.first
    expectations[method][args.first]
  end

private

  @@expectations = nil

  def self.expectations
    return @@expectations if @@expectations

    file = File.read File.join(File.dirname(__FILE__), "wsdl_fixture.yml")
    @@expectations = YAML.load ERB.new(file).result
  end

  @@wsdl = {}

  def self.wsdl(wsdl)
    return @@wsdl[wsdl] if @@wsdl[wsdl]

    file = File.read File.join(File.dirname(__FILE__), "xml", "#{wsdl}.xml")
    @@wsdl[wsdl] = file
  end

end
