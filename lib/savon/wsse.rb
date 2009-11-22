module Savon
  module WSSE

    # Namespace for WS Security Secext.
    WSENamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"

    # Namespace for WS Security Utility.
    WSUNamespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"

    def wsse_header(header)
      header.wsse(:Security, "xmlns:wsse" => WSENamespace) {
        header.wsse(:UsernameToken, "xmlns:wsu" => WSUNamespace) {
          wsse_credentials header
        }
      }
    end

  private

    def wsse_credentials(header)
      created_at = Time.now.strftime Savon::SOAPDateTimeFormat

      header.wsse :Username, savon_config.wsse_username
      header.wsse :Nonce, wsse_nonce(created_at)
      header.wsu :Created, created_at
      wsse_password header, created_at
    end

    def wsse_password(header, created_at)
      if savon_config.wsse_digest
        token = wsse_nonce(created_at) + created_at + savon_config.wsse_password
        password = Base64.encode64(Digest::SHA1.hexdigest(token)).chomp!
      else
        password = savon_config.wsse_password
      end

      header.wsse :Password, password
    end

    # Returns a random WSSE nonce. Expects +Time.now+ for +created+.
    def wsse_nonce(random = nil)
      random ||= Time.now.to_i
      Digest::SHA1.hexdigest(random_string + random.to_s)
    end

    # Returns a random string of a given +length+. Defaults to 100 characters.
    def random_string(length = 100)
      (0...length).map { ("a".."z").to_a[rand(26)] }.join
    end

  end
end