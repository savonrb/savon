# frozen_string_literal: true

module Savon
  module Model
    def self.extended(base)
      base.setup
    end

    def setup
      class_operation_module
      instance_operation_module
    end

    # Accepts one or more SOAP operations and generates both class and instance methods named
    # after the given operations. Each generated method accepts an optional SOAP message Hash.
    def operations(*operations)
      operations.each do |operation|
        define_class_operation(operation)
        define_instance_operation(operation)
      end
    end

    def all_operations
      operations(*client.operations)
    end

    private

    # Defines a class-level SOAP operation.
    def define_class_operation(operation)
      method_name = operation_method_name(operation)

      class_operation_module.define_method(method_name) do |locals = {}|
        client.call operation, locals
      end
    end

    # Defines an instance-level SOAP operation.
    def define_instance_operation(operation)
      method_name = operation_method_name(operation)

      instance_operation_module.define_method(method_name) do |locals = {}|
        self.class.public_send(method_name, locals)
      end
    end

    # Returns the generated Ruby method name for a SOAP operation.
    def operation_method_name(operation)
      StringUtils.snakecase(operation.to_s).to_sym
    end

    # Class methods.
    def class_operation_module
      @class_operation_module ||= Module.new do
        # Configures and returns the model's Savon::Client. The first call
        # with options is the configuration, later options are ignored.
        # With +future: true+ in the configuration, creation is deferred
        # until first use, so options recorded by +global+ become part of
        # one client. The configuring call then returns nil.
        def client(globals = {})
          if globals.any?
            @client_globals ||= globals.dup
            return if @client_globals[:future]
          end

          @client ||= Savon::Client.new(@client_globals || {})
        rescue InitializationError
          raise_initialization_error!
        end

        # Sets a single global option. With +future: true+ this records
        # into the configuration of the not-yet-created client. Without
        # the flag it mutates the live client, as it always has.
        def global(option, *value)
          if @client.nil? && @client_globals && @client_globals[:future]
            # Constructor setters take one argument, so single values are
            # unwrapped the way []= would flatten them.
            @client_globals[option] = value.size == 1 ? value.first : value
          else
            client.globals[option] = value
          end
        end

        def raise_initialization_error!
          raise InitializationError,
                "Expected the model to be initialized with either a WSDL document or the SOAP endpoint and target namespace options.\n" \
                "Make sure to setup the model by calling the .client class method before calling the .global method.\n\n" \
                "client(wsdl: '/Users/me/project/service.wsdl')                              # to use a local WSDL document\n" \
                "client(wsdl: 'http://example.com?wsdl')                                     # to use a remote WSDL document\n" \
                "client(endpoint: 'http://example.com', namespace: 'http://v1.example.com')  # if you don't have a WSDL document"
        end
      end.tap { |mod| extend(mod) }
    end

    # Instance methods.
    def instance_operation_module
      @instance_operation_module ||= Module.new do
        def client
          self.class.client
        end
      end.tap { |mod| include(mod) }
    end
  end
end
