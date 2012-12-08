require "savon/soap/xml"
require "savon/soap/request"
require "savon/soap/response"
require "akami"
require "httpi"

module Savon
  class Operation

    def self.create(operation_name, wsdl, options)
      ensure_exists! operation_name, wsdl
      new(operation_name, wsdl, options)
    end

    def self.ensure_exists!(operation_name, wsdl)
      unless wsdl.soap_actions.include? operation_name
        raise ArgumentError, "Unable to find SOAP operation: #{operation_name}\n" \
                             "Operations provided by your service: #{wsdl.soap_actions.inspect}"
      end
    end

    def initialize(name, wsdl, options)
      @name = name
      @wsdl = wsdl
      @options = options
    end

    def call(options = {})
      @options.set(:request, options)

      http = create_http(@options)
      wsse = create_wsse(@options)
      soap = create_soap(@options)
      soap.wsse = wsse

      request = SOAP::Request.new(@options, http, soap)
      response = request.response

      # XXX: leaving this out for now [dh, 2012-12-06]
      #if wsse.verify_response
        #WSSE::VerifySignature.new(response.http.body).verify!
      #end

      response
    end

    private

    def create_soap(options)
      soap = SOAP::XML.new(options)
      soap.body = options.message
      soap.xml = options.xml

      soap.endpoint = @wsdl.endpoint
      soap.element_form_default = @wsdl.element_form_default

      soap.namespace = namespace
      soap.namespace_identifier = namespace_identifier

      add_wsdl_namespaces_to_soap(soap)
      add_wsdl_types_to_soap(soap)

      # XXX: leaving out the option to set attributes on the input tag for now [dh, 2012-12-06]
      soap.input = [namespace_identifier, soap_input_tag.to_sym, {}] # attributes]
      soap
    end

    def create_wsse(options)
      # XXX: not supported right now [dh, 2012-12-06]
      Akami.wsse
    end

    def create_http(options)
      http = HTTPI::Request.new

      http.proxy = options.proxy if options.proxy
      http.set_cookies(options.last_response) if options.last_response

      http.open_timeout = options.open_timeout if options.open_timeout
      http.read_timeout = options.read_timeout if options.read_timeout

      http.headers = options.headers if options.headers
      http.headers["SOAPAction"] ||= %{"#{soap_action}"}

      http
    end

    def soap_input_tag
      @wsdl.soap_input(@name.to_sym)
    end

    def soap_action
      @wsdl.soap_action(@name.to_sym)
    end

    def namespace
      # XXX: why the fallback? [dh, 2012-11-24]
      #if operation_namespace_defined_in_wsdl?
        @wsdl.parser.namespaces[namespace_identifier.to_s]
      #else
        #@wsdl.namespace
      #end
    end

    def namespace_identifier
      @wsdl.operations[@name][:namespace_identifier].to_sym
    end

    def add_wsdl_namespaces_to_soap(soap)
      @wsdl.type_namespaces.each do |path, uri|
        soap.use_namespace(path, uri)
      end
    end

    def add_wsdl_types_to_soap(soap)
      @wsdl.type_definitions.each do |path, type|
        soap.types[path] = type
      end
    end

  end
end
