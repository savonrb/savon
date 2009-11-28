module Savon
  module Validation

    # Valid SOAP versions.
    SOAPVersions = [1, 2]

    # Validates a given +value+ of a given +type+. Raises an ArgumentError
    # in case the value is not valid. 
    def validate!(type, value)
      case type
        when :endpoint then validate_endpoint value
        when :soap_version then validate_soap_version value
        when :soap_body then validate_soap_body value
        when :response_process then validate_response_process value
        when :wsse_credentials then validate_wsse_credentials value
      end
      true
    end

  private

    # Validates a given +endpoint+.
    def validate_endpoint(endpoint)
      invalid :endpoint, endpoint unless /^(http|https):\/\// === endpoint
    end

    # Validates a given +soap_version+.
    def validate_soap_version(soap_version)
      invalid :soap_version, soap_version unless SOAPVersions.include? soap_version
    end

    # Validates a given +soap_body+.
    def validate_soap_body(soap_body)
      invalid :soap_body, soap_body unless
        soap_body.kind_of?(Hash) || soap_body.respond_to?(:to_s)
    end

    # Validates a given +response_block+.
    def validate_response_process(response_process)
      invalid :response_process, response_process unless
        response_process.respond_to? :call
    end

    # Validates a given Hash of +wsse_credentials+.
    def validate_wsse_credentials(wsse)
      invalid :wsse_credentials unless wsse[:username] && wsse[:password]
      invalid :wsse_username, wsse[:username] unless wsse[:username].respond_to? :to_s
      invalid :wsse_password, wsse[:password] unless wsse[:password].respond_to? :to_s
    end

    # Raises an ArgumentError for a given +argument+. Also accepts the invalid
    # +value+ and adds it to the error message.
    def invalid(argument, value = nil)
      message = "Invalid argument '#{argument}'"
      message << ": #{value}" if value
      raise ArgumentError, message
    end

  end
end
