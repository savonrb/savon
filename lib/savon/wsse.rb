module Savon

  # = Savon::WSSE
  #
  # Savon::WSSE represents WSSE authentication. Pass a block to your SOAP call and the WSSE object
  # is passed to it as the second argument. The object allows setting the WSSE username, password
  # and whether to use digest authentication.
  #
  # == Credentials
  #
  # By default, Savon does not use WSSE authentication. Simply specify a username and password to
  # change this.
  #
  #   response = client.get_all_users do |soap, wsse|
  #     wsse.username = "eve"
  #     wsse.password = "secret"
  #   end
  #
  # == Digest
  #
  # To use WSSE digest authentication, just use the digest method and set it to +true+.
  #
  #   response = client.get_all_users do |soap, wsse|
  #     wsse.username = "eve"
  #     wsse.password = "secret"
  #     wsse.digest = true
  #   end
  #
  # == Default to WSSE
  #
  # In case all you're services require WSSE authentication, you can set your credentials and whether
  # to use WSSE digest for every request:
  #
  #   Savon::WSSE.username = "eve"
  #   Savon::WSSE.password = "secret"
  #   Savon::WSSE.digest = true
  class WSSE

    # Base address for WSSE docs.
    BaseAddress = "http://docs.oasis-open.org/wss/2004/01"

    # Namespace for WS Security Secext.
    WSENamespace = "#{BaseAddress}/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "#{BaseAddress}/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    # URI for "wsse:Password/@Type" #PasswordText.
    PasswordTextURI = "#{BaseAddress}/oasis-200401-wss-username-token-profile-1.0#PasswordText"

    # URI for "wsse:Password/@Type" #PasswordDigest.
    PasswordDigestURI = "#{BaseAddress}/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"

    # Global WSSE username.
    @@username = nil

    # Returns the global WSSE username.
    def self.username
      @@username
    end

    # Sets the global WSSE username.
    def self.username=(username)
      @@username = username.nil? ? nil : username.to_s
    end

    # Global WSSE password.
    @@password = nil

    # Returns the global WSSE password.
    def self.password
      @@password
    end

    # Sets the global WSSE password.
    def self.password=(password)
      @@password = password.nil? ? nil : password.to_s
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
      @username = username.nil? ? nil : username.to_s
    end

    # Returns the WSSE username. Defaults to the global setting.
    def username
      @username || self.class.username
    end

    # Sets the WSSE password per request.
    def password=(password)
      @password = password.nil? ? nil : password.to_s
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

    # Returns the XML for a WSSE header or an empty String unless both username and password
    # were specified.
    def header
      return "" unless username && password

      builder = Builder::XmlMarkup.new
      builder.wsse :Security, "xmlns:wsse" => WSENamespace do |xml|
        xml.wsse :UsernameToken, "xmlns:wsu" => WSUNamespace do
          xml.wsse :Username, username
          xml.wsse :Nonce, nonce
          xml.wsu :Created, timestamp
          xml.wsse :Password, password_node, :Type => password_type
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

    # Returns the URI for the "wsse:Password/@Type" attribute.
    def password_type
      digest? ? PasswordDigestURI : PasswordTextURI
    end

    # Returns a WSSE nonce.
    def nonce
      @nonce ||= Digest::SHA1.hexdigest String.random + timestamp
    end

    # Returns a WSSE timestamp.
    def timestamp
      @timestamp ||= Time.now.strftime Savon::SOAP::DateTimeFormat
    end

  end
end
