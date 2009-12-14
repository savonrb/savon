module Savon

  # Savon::WSSE
  #
  # Represents parameters for WSSE authentication.
  class WSSE

    # Namespace for WS Security Secext.
    WSENamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    # Global WSSE username.
    @@username = nil

    # Returns the global WSSE username.
    def self.username
      @@username
    end

    # Sets the global WSSE username.
    def self.username=(username)
      @@username = username.to_s if username.respond_to? :to_s
      @@username = nil if username.nil?
    end

    # Global WSSE password.
    @@password = nil

    # Returns the global WSSE password.
    def self.password
      @@password
    end

    # Sets the global WSSE password.
    def self.password=(password)
      @@password = password.to_s if password.respond_to? :to_s
      @@password = nil if password.nil?
    end

    # Global setting of whether to use WSSE digest.
    @@digest = false

    # Returns the global setting of whether to use WSSE digest.
    def self.digest?
      @@digest
    end

    # Global setting of whether to use WSSE digest.
    def self.digest=(digest)
      @@digest = digest
    end

    # Sets the WSSE username per request.
    def username=(username)
      @username = username.to_s if username.respond_to? :to_s
      @username = nil if username.nil?
    end

    # Returns the WSSE username. Defaults to the global setting.
    def username
      @username || self.class.username
    end

    # Sets the WSSE password per request.
    def password=(password)
      @password = password.to_s if password.respond_to? :to_s
      @password = nil if password.nil?
    end

    # Returns the WSSE password. Defaults to the global setting.
    def password
      @password || self.class.password
    end

    # Sets whether to use WSSE digest per request.
    attr_writer :digest

    # Returns whether to use WSSE digest. Defaults to the global setting. 
    def digest?
      @digest || self.class.digest?
    end

    # Returns the XML for a WSSE header or an empty String unless both
    # username and password were specified.
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
