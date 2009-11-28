module Savon
  module WSSE

    # Namespace for WS Security Secext.
    WSENamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    def wsse_header(xml)
      xml.wsse :Security, "xmlns:wsse" => WSENamespace do
        xml.wsse :UsernameToken, "xmlns:wsu" => WSUNamespace do
          wsse_credentials xml
        end
      end
    end

    def wsse?
      options[:wsse].kind_of?(Hash) &&
        options[:wsse][:username] && options[:wsse][:password]
    end

  private

    def wsse_credentials(xml)
      xml.wsse :Username, options[:wsse][:username]
      xml.wsse :Nonce, wsse_nonce
      xml.wsu :Created, wsse_timestamp
      xml.wsse :Password, wsse_password
    end

    def wsse_password
      return options[:wsse][:password] unless digest?

      token = wsse_nonce + wsse_timestamp + options[:wsse][:password]
      Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!
    end

    # Returns a random WSSE nonce. Expects +Time.now+ for +created+.
    def wsse_nonce
      Digest::SHA1.hexdigest random_string + wsse_timestamp
    end

    def wsse_timestamp
      @wsse_timestamp ||= Time.now.strftime Savon::SOAPDateTimeFormat
    end

    # Returns a random String of a given +length+.
    def random_string(length = 100)
      (0...length).map { ("a".."z").to_a[rand(26)] }.join
    end

    def digest?
      options[:wsse].kind_of? Hash && options[:wsse][:digest]
    end

  end
end