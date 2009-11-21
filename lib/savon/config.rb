require "singleton"
require "rexml/document"
require "rubygems"
require "cobravsmongoose"

module Savon
  class Config
    include Singleton

    # Supported SOAP versions.
    SOAPVersions = [1, 2]

    class << self
      attr_accessor :default_soap_version, :default_response_process,
        :default_wsse_username, :default_wsse_password, :default_wsse_digest
    end

    # The default SOAP version.
    @@default_soap_version = 1

    # Sets the SOAP version.
    def soap_version=(soap_version)
      @soap_version = soap_version if SOAPVersions.include? soap_version
    end

    # Returns the SOAP version. Defaults to +@@default_soap_version+.
    def soap_version
      @soap_version || @@default_soap_version
    end

    # The default response processing.
    @@default_response_process = lambda do |response|
      doc = REXML::Document.new response.body
      nodes = doc.elements["//return"]

      if nodes.parent.elements.size > 1
        doc.elements.collect("//return") do |node|
          CobraVsMongoose.xml_to_hash(node.to_s)["return"].soap_response_mapping
        end
      else
        CobraVsMongoose.xml_to_hash(nodes.to_s)["return"].soap_response_mapping
      end
    end

    # Sets the response processing.
    def response_process=(response_process)
      @response_process = response_process if response_process.respond_to? :call
    end

    # Returns the response processing. Defaults to +@@default_response_process+.
    def response_process
      @response_process || @@default_response_process
    end

    @@default_wsse_username = nil

    # Sets the username for WSSE authentication.
    def wsse_username=(wsse_username)
      @wsse_username = wsse_username.to_s if wsse_username.respond_to? :to_s
    end

    # Returns the username for WSSE authentication. Defaults to +@@default_wsse_username+.
    def wsse_username
      @wsse_username || @@default_wsse_username
    end

    @@default_wsse_password = nil

    # Sets the password for WSSE authentication.
    def wsse_password=(wsse_password)
      @wsse_password = wsse_password.to_s if wsse_password.respond_to? :to_s
    end

    # Returns the password for WSSE authentication.
    # Defaults to +@@default_wsse_password+.
    def wsse_password
      @wsse_password || @@default_wsse_password      
    end

    @@default_wsse_digest = false

    # Sets whether to use WSSE digest authentication.
    attr_writer :wsse_digest

    # Returns whether to use WSSE digest authentication.
    def wsse_digest
      @wsse_digest || @@default_wsse_digest
    end

    # Returns whether to use WSSE authentication.
    def wsse?
      wsse_username && wsse_password
    end

    # Resets all options.
    def reset!
      all_options.each { |ivar| instance_variable_set "@#{ivar}", nil }
    end

    # Sets up options from a given Hash of +options+.
    def setup(options)
      return unless options.kind_of? Hash

      self.soap_version = options[:soap_version]
      setup_wsse options[:wsse]
    end

    # Sets up WSSE authentication from a given Hash of +wsse+ options.
    def setup_wsse(wsse)
      return unless wsse.kind_of? Hash

      self.wsse_username = wsse[:username]
      self.wsse_password = wsse[:password]
      self.wsse_digest = wsse[:digest]
    end

  private

    # Returns an Array containing all options.
    def all_options
      %w(soap_version response_process wsse_username wsse_password wsse_digest)
    end

  end
end
