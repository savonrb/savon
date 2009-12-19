class WSDLFixture

  def self.authentication(value = nil)
    case value
      when :namespace_uri then "http://v1_0.ws.auth.order.example.com/"
      when :operations    then { :authenticate => { :action => "authenticate", :input => "authenticate" } }
      when :soap_actions  then [:authenticate]
      else                load_fixture :authentication
    end
  end

private

  def self.load_fixture(fixture)
    File.read File.join(File.dirname(__FILE__), "xml", "#{fixture}.xml")
  end

end
