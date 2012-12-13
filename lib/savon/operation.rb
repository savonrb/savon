require "savon/options"
require "savon/request"
require "savon/builder"
require "akami"
require "httpi"

module Savon
  class Operation

    def self.create(operation_name, wsdl, globals)
      if wsdl.document?
        ensure_name_is_symbol! operation_name
        ensure_exists! operation_name, wsdl
      end

      new(operation_name, wsdl, globals)
    end

    def self.ensure_exists!(operation_name, wsdl)
      unless wsdl.soap_actions.include? operation_name
        raise ArgumentError, "Unable to find SOAP operation: #{operation_name.inspect}\n" \
                             "Operations provided by your service: #{wsdl.soap_actions.inspect}"
      end
    end

    def self.ensure_name_is_symbol!(operation_name)
      unless operation_name.kind_of? Symbol
        raise ArgumentError, "Expected the first parameter (the name of the operation to call) to be a symbol\n" \
                             "Actual: #{operation_name.inspect} (#{operation_name.class})"
      end
    end

    def initialize(name, wsdl, globals)
      @name = name
      @wsdl = wsdl
      @globals = globals
    end

    def call(locals = {})
      @locals = LocalOptions.new(locals)

      set_global_endpoint
      set_global_namespace
      set_global_env_namespace
      set_global_element_form_default
      set_global_namespace_identifier

      set_local_soap_action
      set_local_message_tag

      builder = Builder.new(@name, @wsdl, @globals, @locals)
      add_wsdl_namespaces_to_builder(builder)
      add_wsdl_types_to_builder(builder)

      request = Request.new(@globals, @locals)
      response = request.call(builder.to_s)

      # XXX: leaving this out for now [dh, 2012-12-06]
      #if wsse.verify_response
        #WSSE::VerifySignature.new(response.http.body).verify!
      #end

      response
    end

    private

    def set_global_endpoint
      return if @globals.include?(:endpoint)
      raise_error_for_missing_no_wsdl_option! :endpoint unless @wsdl.document?

      @globals[:endpoint] = @wsdl.endpoint
    end

    def set_global_namespace
      return if @globals.include?(:namespace)
      raise_error_for_missing_no_wsdl_option! :namespace unless @wsdl.document?

      @globals[:namespace] = @wsdl.namespace
    end

    def set_global_env_namespace
      return if @globals.include? :env_namespace
      @globals[:env_namespace] = :env
    end

    def set_global_element_form_default
      return if @globals.include? :element_form_default
      @globals[:element_form_default] = @wsdl.element_form_default
    end

    def set_global_namespace_identifier
      return if @globals.include? :namespace_identifier

      if @wsdl.document?
        operation = @wsdl.operations[@name]
        identifier = operation[:namespace_identifier] if operation
      end

      identifier ||= "wsdl"

      @globals[:namespace_identifier] = identifier.to_sym
    end

    def set_local_soap_action
      return if @locals.include? :soap_action

      soap_action = @wsdl.soap_action(@name.to_sym) if @wsdl.document?
      soap_action ||= Gyoku::XMLKey.create(@name)

      @locals[:soap_action] = soap_action
    end

    def set_local_message_tag
      return if @locals.include? :message_tag

      message_tag = @wsdl.soap_input(@name.to_sym) if @wsdl.document?
      message_tag ||= Gyoku::XMLKey.create(@name)

      @locals[:message_tag] = message_tag
    end

    def add_wsdl_namespaces_to_builder(builder)
      @wsdl.type_namespaces.each do |path, uri|
        builder.use_namespace(path, uri)
      end
    end

    def add_wsdl_types_to_builder(builder)
      @wsdl.type_definitions.each do |path, type|
        builder.types[path] = type
      end
    end

    def raise_error_for_missing_no_wsdl_option!(option)
      raise ArgumentError, "Expected the global :#{option} option to be specified to work without a WSDL document.\n" \
                             "Please make sure to specify both global :endpoint and :namespace options or provide a WSDL document."
    end

  end
end
