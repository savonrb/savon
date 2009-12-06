module Savon

  # Savon::WSSE
  #
  # Represents parameters for WSSE authentication.
  class WSSE

    # Namespace for WS Security Secext.
    WSENamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    # Default WSSE username.
    @username = nil

    # Default WSSE password.
    @password = nil

    # Default for whether to use WSSE digest.
    @digest = false

    class << self

      # Returns the default WSSE username.
      attr_reader :username

      # Sets the default WSSE username.
      def username=(username)
        @username = username.to_s if username.respond_to? :to_s
        @username = nil if username.nil?
      end

      # Returns the default WSSE password.
      attr_reader :password

      # Sets the default WSSE password.
      def password=(password)
        @password = password.to_s if password.respond_to? :to_s
        @password = nil if password.nil?
      end

      # Sets whether to use WSSE digest by default.
      attr_writer :digest

      # Returns whether to use WSSE digest by default.
      def digest?
        @digest
      end

    end

    # Sets the WSSE username.
    def username=(username)
      @username = username.to_s if username.respond_to? :to_s
      @username = nil if username.nil?
    end

    # Returns the WSSE username. Defaults to the global default.
    def username
      @username || self.class.username
    end

    # Sets the WSSE password.
    def password=(password)
      @password = password.to_s if password.respond_to? :to_s
      @password = nil if password.nil?
    end

    # Returns the WSSE password. Defaults to the global default.
    def password
      @password || self.class.password
    end

    # Sets whether to use WSSE digest.
    attr_writer :digest

    # Returns whether to use WSSE digest. Defaults to the global default. 
    def digest?
      @digest || self.class.digest?
    end

    # Returns the XML for a WSSE header or an empty String unless username
    # and password are specified.
    def header
      return "" unless username && password

      builder = Builder::XmlMarkup.new
      builder.wsse :Security, "xmlns:wsse" => WSENamespace do |xml|
        xml.wsse :UsernameToken, "xmlns:wsu" => WSUNamespace do
          xml.wsse :Username, username
          xml.wsse :Nonce, nonce
          xml.wsu :Created, timestamp
          xml.wsse :Password, password_node
        end
      end
    end

  private

    # Returns the WSSE password. Encrypts the password for digest authentication.
    def password_node
      return password unless digest?

      token = nonce + timestamp + password
      Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!
    end

    # Returns a WSSE nonce.
    def nonce
      @nonce ||= Digest::SHA1.hexdigest String.random + timestamp
    end

    # Returns a WSSE timestamp.
    def timestamp
      @timestamp ||= Time.now.strftime Savon::SOAPDateTimeFormat
    end

  end
end
