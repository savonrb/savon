module Savon
  module SOAP

    # = Savon::SOAP::RequestBuilder
    #
    # Savon::SOAP::RequestBuilder builds Savon::SOAP::Request instances.
    # The RequestBuilder is configured by the client that instantiates it.
    # It uses the options set by the client to build an appropriate request.
    class RequestBuilder

      # Initialize a new +RequestBuilder+ with the given SOAP operation.
      # The operation may be specified using a symbol or a string.
      def initialize(operation, options = {})
        @operation = operation
        assign_options(options)
      end

      # Writer for the <tt>HTTPI::Request</tt> object.
      attr_writer :http

      # Writer for the <tt>Savon::SOAP::XML</tt> object.
      attr_writer :soap

      # Writer for the <tt>Akami::WSSE</tt> object.
      attr_writer :wsse

      # Writer for the <tt>Wasabi::Document</tt> object.
      attr_writer :wsdl

      # Writer for the <tt>Savon::Config</tt> object.
      attr_writer :config

      # Writer for the attributes of the SOAP input tag. Accepts a Hash.
      attr_writer :attributes

      # Writer for the namespace identifer of the <tt>Savon::SOAP::XML</tt>
      # object.
      attr_writer :namespace_identifier

      # Writer for the SOAP action of the <tt>Savon::SOAP::XML</tt> object.
      attr_writer :soap_action

      # Reader for the operation of the request being built by the request builder.
      attr_reader :operation

      # Builds and returns a <tt>Savon::SOAP::Request</tt> object. You may optionally
      # pass a block to the method that will be run after the initial configuration of
      # the dependencies. +self+ will be yielded to the block if the block accepts an
      # argument.
      def request(&post_configuration_block)
        configure_dependencies

        if post_configuration_block
          # Only yield self to the block if our block takes an argument
          args = [] and (args << self if post_configuration_block.arity == 1)
          post_configuration_block.call(*args)
        end

        Request.new(config, http, soap)
      end

      # Returns the identifier for the default namespace. If an operation namespace
      # identifier is defined for the current operation in the WSDL document, this
      # namespace identifier is used. Otherwise, the +@namespace_identifier+ instance
      # variable is used.
      def namespace_identifier
        if operation_namespace_defined_in_wsdl?
          wsdl.operations[operation][:namespace_identifier].to_sym
        else
          @namespace_identifier
        end
      end

      # Returns the namespace identifier to be used for the the SOAP input tag.
      # If +@namespace_identifier+ is not +nil+, it will be returned. Otherwise, the
      # default namespace identifier as returned by +namespace_identifier+ will be
      # returned.
      def input_namespace_identifier
        @namespace_identifier || namespace_identifier
      end

      # Returns the default namespace to be used for the SOAP request. If a namespace
      # is defined for the operation in the WSDL document, this namespace will be
      # returned. Otherwise, the default WSDL document namespace will be returned.
      def namespace
        if operation_namespace_defined_in_wsdl?
          wsdl.parser.namespaces[namespace_identifier.to_s]
        else
          wsdl.namespace
        end
      end

      # Returns true if the operation's namespace is defined within the WSDL
      # document.
      def operation_namespace_defined_in_wsdl?
        return false unless wsdl.document?
        (operation = wsdl.operations[self.operation]) && operation[:namespace_identifier]
      end

      # Returns the SOAP action. If +@soap_action+ has been defined, this will
      # be returned. Otherwise, if there is a WSDL document defined, the SOAP
      # action corresponding to the operation will be returned. Failing this,
      # the operation name will be used to form the SOAP action.
      def soap_action
        return @soap_action if @soap_action

        if wsdl.document?
          wsdl.soap_action(operation.to_sym)
        else
          Gyoku::XMLKey.create(operation).to_sym
        end
      end

      # Returns the SOAP operation input tag. If there is a WSDL document defined,
      # and the operation's input tag is defined in the document, this will be
      # returned. Otherwise, the operation name will be used to form the input tag.
      def soap_input_tag
        if wsdl.document? && (input = wsdl.soap_input(operation.to_sym))
          input
        else
          Gyoku::XMLKey.create(operation)
        end
      end

      # Changes the body of the SOAP request to +body+.
      def body=(body)
        soap.body = body
      end

      # Returns the body of the SOAP request.
      def body
        soap.body
      end

      # Returns the attributes of the SOAP input tag. Defaults to
      # an empty Hash.
      def attributes
        @attributes ||= {}
      end

      # Returns the <tt>Savon::Config</tt> object for the request. Defaults
      # to a clone of <tt>Savon.config</tt>.
      def config
        @config ||= Savon.config.clone
      end

      # Returns the <tt>HTTPI::Request</tt> object.
      def http
        @http ||= HTTPI::Request.new
      end

      # Returns the <tt>SOAP::XML</tt> object.
      def soap
        @soap ||= XML.new(config)
      end

      # Returns the <tt>Wasabi::Document</tt> object.
      def wsdl
        @wsdl ||= Wasabi::Document.new
      end

      # Returns the <tt>Akami::WSSE</tt> object.
      def wsse
        @wsse ||= Akami.wsse
      end

      private

      def configure_dependencies
        soap.endpoint = wsdl.endpoint
        soap.element_form_default = wsdl.element_form_default
        soap.wsse = wsse

        soap.namespace = namespace
        soap.namespace_identifier = namespace_identifier

        add_wsdl_namespaces_to_soap
        add_wsdl_types_to_soap

        soap.input = [input_namespace_identifier, soap_input_tag.to_sym, attributes]

        http.headers["SOAPAction"] = %{"#{soap_action}"}
      end

      def add_wsdl_namespaces_to_soap
        wsdl.type_namespaces.each do |path, uri|
          soap.use_namespace(path, uri)
        end
      end

      def add_wsdl_types_to_soap
        wsdl.type_definitions.each do |path, type|
          soap.types[path] = type
        end
      end

      def assign_options(options)
        options.each do |option, value|
          send(:"#{option}=", value) if value
        end
      end

    end
  end
end
