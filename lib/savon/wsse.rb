require "base64"
require "digest/sha1"

require "savon/core_ext/string"
require "savon/core_ext/hash"
require "savon/core_ext/time"

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

    # Returns a value from the WSSE Hash.
    def [](key)
      hash[key]
    end

    # Sets a value on the WSSE Hash.
    def []=(key, value)
      hash[key] = value
    end

    # Sets authentication credentials for a wsse:UsernameToken header.
    # Also accepts whether to use WSSE digest authentication.
    def credentials(username, password, digest = false)
      self.username = username
      self.password = password
      self.digest = digest
    end

    attr_accessor :username, :password, :created_at, :expires_at

    # Returns whether to use WSSE digest. Defaults to +false+.
    def digest?
      !!@digest
    end

    attr_writer :digest

    # Returns whether to generate a wsse:UsernameToken header.
    def username_token?
      username && password
    end

    # Returns whether to generate a wsse:Timestamp header.
    def timestamp?
      created_at || expires_at || @wsse_timestamp
    end

    # Sets whether to generate a wsse:Timestamp header.
    def timestamp=(timestamp)
      @wsse_timestamp = timestamp
    end

    # Returns the XML for a WSSE header.
    def to_xml
      if username_token? && timestamp?
        Gyoku.xml wsse_username_token.merge!(wsse_timestamp) {
          |key, v1, v2| v1.merge!(v2) {
            |key, v1, v2| v1.merge!(v2)
          }
        }
      elsif username_token?
        Gyoku.xml wsse_username_token.merge!(hash)
      elsif timestamp?
        Gyoku.xml wsse_timestamp.merge!(hash)
      else
        ""
      end
    end

  private

    # Returns a Hash containing wsse:UsernameToken details.
    def wsse_username_token
      if digest?
        wsse_security "UsernameToken",
          "wsse:Username" => username,
          "wsse:Nonce" => nonce,
          "wsu:Created" => timestamp,
          "wsse:Password" => digest_password,
          :attributes! => { "wsse:Password" => { "Type" => PasswordDigestURI } }
      else
        wsse_security "UsernameToken",
          "wsse:Username" => username,
          "wsse:Password" => password,
          :attributes! => { "wsse:Password" => { "Type" => PasswordTextURI } }
      end
    end

    # Returns a Hash containing wsse:Timestamp details.
    def wsse_timestamp
      wsse_security "Timestamp",
        "wsu:Created" => (created_at || Time.now).xs_datetime,
        "wsu:Expires" => (expires_at || (created_at || Time.now) + 60).xs_datetime
    end

    # Returns a Hash containing wsse:Security details for a given +tag+ and +hash+.
    def wsse_security(tag, hash)
      {
        "wsse:Security" => {
          "wsse:#{tag}" => hash,
          :attributes! => { "wsse:#{tag}" => { "wsu:Id" => "#{tag}-#{count}", "xmlns:wsu" => WSUNamespace } }
        },
        :attributes! => { "wsse:Security" => { "xmlns:wsse" => WSENamespace } }
      }
    end

    # Returns the WSSE password, encrypted for digest authentication.
    def digest_password
      token = nonce + timestamp + password
      Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!
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
      @timestamp ||= Time.now.xs_datetime
    end

    # Returns a new number with every call.
    def count
      @count ||= 0
      @count += 1
    end

    # Returns a memoized and autovivificating Hash.
    def hash
      @hash ||= Hash.new { |h, k| h[k] = Hash.new(&h.default_proc) }
    end

  end
end
