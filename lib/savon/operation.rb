require "savon/soap/xml"
require "savon/soap/request"
require "akami"
require "httpi"

module Savon
  class Operation

    def self.create(operation_name, wsdl, options)
      if wsdl.document?
        ensure_name_is_symbol! operation_name
        ensure_exists! operation_name, wsdl
      end

      new(operation_name, wsdl, options)
    end

    def self.ensure_exists!(operation_name, wsdl)
      unless wsdl.soap_actions.include? operation_name
        raise ArgumentError, "Unable to find SOAP operation: #{operation_name}\n" \
                             "Operations provided by your service: #{wsdl.soap_actions.inspect}"
      end
    end

    def self.ensure_name_is_symbol!(operation_name)
      unless operation_name.kind_of? Symbol
        raise ArgumentError, "Expected the first parameter (the name of the operation to call) to be a symbol\n" \
                             "Actual: #{operation_name.inspect} (#{operation_name.class})"
      end
    end

    def initialize(name, wsdl, options)
      @name = name
      @wsdl = wsdl
      @options = options
    end

    def call(options = {})
      @options = @options.merge(:request, options)

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
      soap.endpoint = @wsdl.endpoint

      soap.body = options.message
      soap.xml = options.xml

      soap.encoding = options.encoding
      soap.env_namespace = options.env_namespace if options.env_namespace
      soap.element_form_default = options.element_form_default || @wsdl.element_form_default

      soap.namespace = namespace(options)
      soap.namespace_identifier = namespace_identifier

      add_wsdl_namespaces_to_soap(soap)
      add_wsdl_types_to_soap(soap)

      # XXX: leaving out the option to set attributes on the input tag for now [dh, 2012-12-06]
      soap.input = [namespace_identifier, message_tag(options).to_sym, {}] # attributes]
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
      http.headers["SOAPAction"] ||= %{"#{soap_action(options)}"}

      http
    end

    def message_tag(options)
      if options.message_tag
        options.message_tag
      elsif @wsdl.document? && (input = @wsdl.soap_input(@name.to_sym))
        input
      else
        Gyoku::XMLKey.create(@name)
      end
    end

    def soap_action(options)
      if options.soap_action
        options.soap_action
      elsif @wsdl.document?
        @wsdl.soap_action(@name.to_sym)
      else
        Gyoku::XMLKey.create(@name).to_sym
      end
    end

    def namespace(options)
      if options.namespace
        options.namespace
      elsif operation_namespace_defined_in_wsdl?
        @wsdl.parser.namespaces[namespace_identifier.to_s]
      else
        @wsdl.namespace
      end
    end

    def namespace_identifier
      return :wsdl unless operation_namespace_defined_in_wsdl?
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

    def operation_namespace_defined_in_wsdl?
      return false unless @wsdl.document?
      (operation = @wsdl.operations[@name]) && operation[:namespace_identifier]
    end

  end
end
