class ResponseFixture
  class << self

    def authentication(value = nil)
      @authentication ||= load_fixture :authentication
      
      case value
        when :to_hash then Savon::SOAP::XML.to_hash(@authentication)[:authenticate_response][:return]
        else               @authentication
      end
    end

    def soap_fault
      @soap_fault ||= load_fixture :soap_fault
    end

    def soap_fault12
      @soap_fault12 ||= load_fixture :soap_fault12
    end

    def multi_ref
      @multi_ref ||= load_fixture :multi_ref
    end

    def list
      @list ||= load_fixture :list
    end

  private

    def load_fixture(fixture)
      File.read File.dirname(__FILE__) + "/xml/#{fixture}.xml"
    end

  end
end
