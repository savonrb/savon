require 'uri'

module Savon
  class Options

    # Supported SOAP versions.
    SoapVersions = [1, 2]

    # The default SOAP version.
    @@default_soap_version = 1

    # Sets the default SOAP version to use.
    def self.default_soap_version=(soap_version)
      @@default_soap_version = soap_version
    end

    # The default XML root node.
    @@default_root_node = "//return"

    # Sets the default XML root node.
    def self.default_root_node=(root_node)
      @@default_root_node = root_node
    end

    # Returns the endpoint.
    attr_reader :endpoint

    # Sets the endpoint to the given +endpoint+.
    def endpoint=(endpoint)
      raise ArgumentError, "Invalid endpoint: #{endpoint}" unless valid_endpoint? endpoint
      @endpoint = URI endpoint
    end

    # Returns the SOAP version. Defaults to +@@default_soap_version+.
    def soap_version
      @soap_version || @@default_soap_version
    end

    # Sets the SOAP version to the given +soap_version+.
    def soap_version=(soap_version)
      raise ArgumentError, "Invalid SOAP version: #{soap_version}" unless valid_soap_version? soap_version
      @soap_version = soap_version
    end

    # Returns the XML root node. Defaults to +@@default_root_node+.
    def root_node
      @root_node || @@default_root_node
    end

    # Sets the XML root node to the given +root_node+.
    def root_node=(root_node)
      @root_node = root_node if root_node.kind_of? String
    end

    # Sets whether the SOAP response should be returned as pure XML.
    attr_writer :xml_response

    # Returns whether the SOAP response should be returned as pure XML.
    def xml_response?
      @xml_response
    end

    # Returns the WSSE username.
    attr_reader :wsse_username

    def wsse_username=(wsse_username)
      @wsse_username = wsse_username if wsse_username.kind_of? String
    end

    # Returns the WSSE password.
    attr_reader :wsse_password

    def wsse_password=(wsse_password)
      @wsse_password = wsse_password if wsse_password.kind_of? String
    end

    # Sets whether WSSE digest should be used. If enabled, the WSSE password
    # will be encrypted automatically.
    attr_writer :wsse_digest

    # Returns whether WSSE digest should be used.
    def wsse_digest?
      @wsse_digest
    end

    # Returns whether WSSE authentication should be used.
    def wsse?
      wsse_username && wsse_password
    end

    # Sets options from a given Hash of +options+.
    def from_hash(options)
      available_options.each { |option| self.send option, options[option] }
    end

  private

    # Returns an Array containing all available options.
    def available_options
      [:soap_version, :root_node, :xml_response, :wsse_username, :wsse_password, :wsse_digest]
    end

    # Returns whether a given +endpoint+ is valid.
    def valid_endpoint?(endpoint)
      /^http.+/ === endpoint
    end

    # Returns whether a given +soap_version+ is valid.
    def valid_soap_version?(soap_version)
      soap_version.kind_of?(Fixnum) && SoapVersions.include?(soap_version)
    end

  end
end
