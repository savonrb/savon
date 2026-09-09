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
    # Raises ArgumentError for reserved model method names, before defining any methods.
    def operations(*operations)
      operations.map { |operation| [operation, operation_method_name(operation)] }.each do |operation, method_name|
        define_class_operation(operation, method_name)
        define_instance_operation(method_name)
      end
      operations
    end

    def all_operations
      operations(*client.operations)
    end

    private

    # Defines a class-level SOAP operation.
    def define_class_operation(operation, method_name)
      class_operation_module.define_method(method_name) do |locals = {}|
        client.call operation, locals
      end
    end

    # Defines an instance-level SOAP operation.
    def define_instance_operation(method_name)
      instance_operation_module.define_method(method_name) do |locals = {}|
        self.class.public_send(method_name, locals)
      end
    end

    # Returns the generated Ruby method name for a SOAP operation.
    def operation_method_name(operation)
      method_name = StringUtils.snakecase(operation.to_s).to_sym
      reserved_methods = Model.instance_methods(false) + Model.private_instance_methods(false) +
                         %i[client global raise_initialization_error!]
      raise ArgumentError, "SOAP operation #{operation.inspect} conflicts with reserved Savon::Model method #{method_name.inspect}" if reserved_methods.include?(method_name)

      method_name
    end

    # Class methods.
    def class_operation_module
      @class_operation_module ||= Module.new do
        def client(globals = {})
          @client ||= Savon::Client.new(globals)
        rescue InitializationError
          raise_initialization_error!
        end

        def global(option, *value)
          client.globals[option] = value
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
