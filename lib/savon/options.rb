require "savon/logger"

module Savon
  class Options

    GLOBAL = [

      # SOAP endpoint.
      :endpoint,

      # Proxy server to use for all requests.
      :proxy,

      # A Hash of HTTP headers.
      :headers,

      # Open timeout in seconds.
      :open_timeout,

      # Read timeout in seconds.
      :read_timeout,

      # The encoding to use. Defaults to "UTF-8".
      :encoding,

      # Sets whether elements should be :qualified or unqualified.
      # If you need to use this option, please open an issue and make
      # sure to add your WSDL document for debugging.
      :element_form_default,

      # Can be used to change the SOAP envelope namespace identifier.
      # If you need to use this option, please open an issue and make
      # sure to add your WSDL document for debugging.
      :env_namespace,

      # Changes the SOAP version to 1 or 2.
      # If you need to use this option, please open an issue and make
      # sure to add your WSDL document for debugging.
      :soap_version,

      # Whether or not to raise SOAP fault and HTTP errors.
      :raise_errors,

      # The logger to use. Defaults to a Savon::Logger instance.
      :logger,

      # Whether to pretty print request and response XML log messages.
      :pretty_print_xml,

      # Used by Savon to store the last response to pass
      # its cookies to the next request.
      :last_response,

      #
      :wsse_auth,

      # XXX: not yet supported [dh, 2012-12-06]
      :soap_header,
      :hooks

    ]

    REQUEST  = [

      # The SOAP message to send. Expected to be a Hash or a String.
      :message,

      # The SOAP request XML to send. Expected to be a String.
      :xml

    ]

    SCOPES   = { :global => GLOBAL, :request => REQUEST }

    DEFAULTS = {
      :encoding     => lambda { "UTF-8" },
      :soap_version => lambda { 1 },
      :logger       => lambda { Logger.new },
      :hooks        => lambda { Class.new { def fire(*) yield end }.new }
    }

    SCOPES.each do |scope_sym, scope|
      scope.each do |option|
        define_method(option) { get(scope_sym, option) }
      end
    end

    def initialize(options = {})
      # only pass in valid options, as there's no validation at this point!
      @options = options
    end

    def add(scope, option, value)
      validate_scope! scope
      validate_option! scope, option

      @options[option] = value
    end

    def set(scope, options)
      validate_scope! scope
      validate_all_options! scope, options

      @options = options
    end

    def merge(scope, options)
      validate_scope! scope
      validate_all_options! scope, options

      Options.new @options.merge(options)
    end

    def get(scope, option)
      validate_scope! scope
      validate_option! scope, option

      default_option = DEFAULTS[option]
      @options[option] ||= default_option ? default_option.call : nil
    end

    private

    def validate_scope!(scope)
      unless SCOPES.include? scope
        raise ArgumentError, "Invalid option scope: #{scope.inspect}\n" \
                             "Available scopes: #{SCOPES.keys.inspect}"
      end
    end

    def validate_option!(scope, option)
      available_options = SCOPES[scope]

      unless available_options.include? option
        raise ArgumentError, "Unknown #{scope} option: #{option.inspect}\n" \
                             "Available options: #{available_options.inspect}"
      end
    end

    def validate_all_options!(scope, options)
      available_options = SCOPES[scope]
      unknown_options   = options.keys - available_options

      unless unknown_options.empty?
        raise ArgumentError, "Unknown #{scope} option(s): #{unknown_options.inspect}\n" \
                             "Available options: #{available_options.inspect}"
      end
    end

  end
end
