require 'uri'

module Savon
  class Options

    # Supported SOAP versions.
    SoapVersions = [1, 2]

    # SOAP namespaces by SOAP version.
    SOAPNamespace = {
      1 => 'http://schemas.xmlsoap.org/soap/envelope/',
      2 => 'http://www.w3.org/2003/05/soap-envelope'
    }

    # The default SOAP version.
    @@soap_version = 1

    # Sets the default SOAP version to use.
    def self.soap_version=(soap_version)
      @@soap_version = soap_version
    end

    # The default response processing.
    @@process_response = lambda do |response|
      doc = Hpricot.XML response.body
      nodes = doc.search '//return'
      
      if nodes.size > 1
        nodes.map { |node| CobraVsMongoose.xml_to_hash node }
      else
        CobraVsMongoose.xml_to_hash nodes
      end
    end

    # Returns a Proc object to process the response.
    def process_response
      @process_response || @@process_response
    end

    # Sets the Proc object to process the response.
    def process_response=(process_response)
      @process_response if process_response.respond_to? :call
    end    

    # Returns the endpoint.
    attr_reader :endpoint

    # Sets the endpoint to the given +endpoint+.
    def endpoint=(endpoint)
      raise ArgumentError, 'Invalid endpoint: #{endpoint}' unless valid_endpoint? endpoint
      @endpoint = URI endpoint
    end

    # Returns the SOAP version. Defaults to +@@default_soap_version+.
    def soap_version
      @soap_version || @@soap_version
    end

    # Sets the SOAP version to the given +soap_version+.
    def soap_version=(soap_version)
      raise ArgumentError, 'Invalid SOAP version: #{soap_version}' unless valid_soap_version? soap_version
      @soap_version = soap_version
    end

    # Returns the XML root node. Defaults to +@@default_root_node+.
    def root_node
      @root_node || @@root_node
    end

    # Sets the XML root node to the given +root_node+.
    def root_node=(root_node)
      @root_node = root_node if root_node.kind_of? String
    end

    attr_reader :namespaces

    def namespaces=(namespaces)
      @namespaces = namespaces if namespaces.kind_of? Hash
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

    def soap_namespace
      SOAPNamespace[soap_version]
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
