module Savon

  # Savon::WSSE
  #
  # Includes support methods for adding WSSE authentication to a SOAP request.
  module WSSE

    # Namespace for WS Security Secext.
    WSENamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    # Returns whether WSSE authentication was set via options.
    def wsse?
      options[:wsse].kind_of?(Hash) &&
      options[:wsse].keys.include?(:username) &&
      options[:wsse].keys.include?(:password)
    end

    # Takes a Builder::XmlMarkup instance and appends a WSSE header.
    def wsse_header(xml)
      xml.wsse :Security, "xmlns:wsse" => WSENamespace do
        xml.wsse :UsernameToken, "xmlns:wsu" => WSUNamespace do
          wsse_credentials xml
        end
      end
    end

  private

    # Takes a Builder::XmlMarkup instance and appends the credentials for
    # WSSE authentication.
    def wsse_credentials(xml)
      xml.wsse :Username, options[:wsse][:username]
      xml.wsse :Nonce, wsse_nonce
      xml.wsu :Created, wsse_timestamp
      xml.wsse :Password, wsse_password
    end

    # Returns the WSSE password. Encrypts the password for digest authentication.
    def wsse_password
      return options[:wsse][:password] unless digest?

      token = wsse_nonce + wsse_timestamp + options[:wsse][:password]
      Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!
    end

    # Returns a WSSE nonce.
    def wsse_nonce
      @wsse_nonce ||= Digest::SHA1.hexdigest random_string + wsse_timestamp
    end

    # Returns a WSSE timestamp.
    def wsse_timestamp
      @wsse_timestamp ||= Time.now.strftime Savon::SOAPDateTimeFormat
    end

    # Returns a random String of a given +length+.
    def random_string(length = 100)
      (0...length).map { ("a".."z").to_a[rand(26)] }.join
    end

    # Returns whether to use WSSE digest authentication based on options.
    def digest?
      options[:wsse][:digest] rescue false
    end

  end
end
