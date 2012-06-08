module Savon

  # = Savon::Model
  #
  # Model for SOAP service oriented applications.
  module Model

    def self.extended(base)
      base.setup
    end

    def setup
      class_action_module
      instance_action_module
    end

    # Accepts one or more SOAP actions and generates both class and instance methods named
    # after the given actions. Each generated method accepts an optional SOAP body Hash and
    # a block to be passed to <tt>Savon::Client#request</tt> and executes a SOAP request.
    def actions(*actions)
      actions.each do |action|
        define_class_action(action)
        define_instance_action(action)
      end
    end

    private

    # Defines a class-level SOAP action method.
    def define_class_action(action)
      class_action_module.module_eval %{
        def #{action.to_s.snakecase}(body = nil, &block)
          client.request :wsdl, #{action.inspect}, :body => body, &block
        end
      }
    end

    # Defines an instance-level SOAP action method.
    def define_instance_action(action)
      instance_action_module.module_eval %{
        def #{action.to_s.snakecase}(body = nil, &block)
          self.class.#{action.to_s.snakecase} body, &block
        end
      }
    end

    # Class methods.
    def class_action_module
      @class_action_module ||= Module.new do

        # Returns the memoized <tt>Savon::Client</tt>.
        def client(&block)
          @client ||= Savon::Client.new(&block)
        end

        # Sets the SOAP endpoint to the given +uri+.
        def endpoint(uri)
          client.wsdl.endpoint = uri
        end

        # Sets the target namespace.
        def namespace(uri)
          client.wsdl.namespace = uri
        end

        # Sets the WSDL document to the given +uri+.
        def document(uri)
          client.wsdl.document = uri
        end

        # Sets the HTTP headers.
        def headers(headers)
          client.http.headers = headers
        end

        # Sets basic auth +login+ and +password+.
        def basic_auth(login, password)
          client.http.auth.basic(login, password)
        end

        # Sets WSSE auth credentials.
        def wsse_auth(*args)
          client.wsse.credentials(*args)
        end

      end.tap { |mod| extend(mod) }
    end

    # Instance methods.
    def instance_action_module
      @instance_action_module ||= Module.new do

        # Returns the <tt>Savon::Client</tt> from the class instance.
        def client(&block)
          self.class.client(&block)
        end

      end.tap { |mod| include(mod) }
    end

  end
end
