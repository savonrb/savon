require "base64"
require "digest/sha1"
require "builder"

require "savon/core_ext/string"
require "savon/soap"

module Savon

  # = Savon::WSSE
  #
  # Provides WSSE authentication.
  class WSSE

    # Namespace for WS Security Secext.
    WSENamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    # URI for "wsse:Password/@Type" #PasswordText.
    PasswordTextURI = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"

    # URI for "wsse:Password/@Type" #PasswordDigest.
    PasswordDigestURI = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"

    # Sets the authentication credentials. Also accepts whether to use WSSE digest.
    def credentials(username, password, digest = false)
      self.username = username
      self.password = password
      self.digest = digest
    end

    attr_accessor :username, :password

    # Returns whether to use WSSE digest. Defaults to +false+.
    def digest?
      !!@digest
    end

    attr_writer :digest

    # Returns the XML for a WSSE header or an empty String unless authentication
    # credentials were specified.
    def to_xml
      return "" unless username && password

      builder = Builder::XmlMarkup.new
      builder.wsse :Security, "xmlns:wsse" => WSENamespace do |xml|
        xml.wsse :UsernameToken, "wsu:Id" => wsu_id, "xmlns:wsu" => WSUNamespace do
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
      @nonce ||= Digest::SHA1.hexdigest random_string + timestamp
    end

    # Returns a random String of 100 characters.
    def random_string
      (0...100).map { ("a".."z").to_a[rand(26)] }.join
    end

    # Returns a WSSE timestamp.
    def timestamp
      @timestamp ||= Time.now.strftime Savon::SOAP::DateTimeFormat
    end

    # Returns the "wsu:Id" attribute.
    def wsu_id
      "UsernameToken-#{count}"
    end

    # Simple counter.
    def count
      @count ||= 0
      @count += 1
    end

  end
end
