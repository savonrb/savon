class EndpointHelper
  class << self

    def wsdl_endpoint(type = nil)
      soap_endpoint(type) << "?wsdl"
    end

    def soap_endpoint(type = nil)
      case type
        when :soap_fault then "http://soapfault.example.com/Service"
        when :http_error then "http://httperror.example.com/Service"
        when :invalid    then "http://invalid.example.com/Service"
        else                  "http://validation.example.com/Service"
      end
    end

  end
end
