module Net
  class HTTP

    # Sets the endpoint +address+ and +port+.
    def endpoint(address, port)
      @address, @port = address, port
    end

    # Convenience method for setting SSL client authentication through a Hash of +options+.
    def ssl_client_auth(options)
      self.use_ssl = true
      self.cert = options[:cert] if options[:cert]
      self.key = options[:key] if options[:key]
      self.ca_file = options[:ca_file] if options[:ca_file]
      self.verify_mode = options[:verify_mode] if options[:verify_mode]
    end

  end
end
