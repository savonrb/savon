class WSDLFixture

  def self.authentication(value = nil)
    case value
      when :namespace_uri then "http://v1_0.ws.auth.order.example.com/"
      when :operations    then { :authenticate => { :action => "authenticate", :input => "authenticate" } }
      when :soap_actions  then [:authenticate]
      else                @authentication ||= load_fixture :authentication
    end
  end

  def self.no_namespace(value = nil)
    case value
      when :namespace_uri then "urn:ActionWebService"
      when :soap_actions  then [:get_all_contacts, :search_user, :get_user_login_by_id]
      else                     @no_namespaces ||= load_fixture :medpass
    end
  end

private

  def self.load_fixture(fixture)
    File.read File.join(File.dirname(__FILE__), "xml", "#{fixture}.xml")
  end

end
