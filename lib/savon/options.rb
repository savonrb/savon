module Savon
  class Options

    GLOBAL   = [ :raise_errors, :env_namespace, :soap_version, :soap_header,
               :hooks, :logger, :pretty_print_xml ]

    REQUEST  = [ :message, :xml ]

    SCOPES   = { :global => GLOBAL, :request => REQUEST }

    DEFAULTS = {

      :soap_version => lambda { 1 },

      :hooks => lambda { Class.new { def fire(*) yield end }.new },

      :logger => lambda { Class.new { def log(msg, *) end }.new }

    }

    SCOPES.each do |scope_sym, scope|
      scope.each do |option|
        define_method(option) { get(scope_sym, option) }
      end
    end

    def initialize
      @options = {}

      SCOPES.each do |scope, _|
        @options[scope] = {}
      end
    end

    def set(scope, options)
      validate_scope! scope
      validate_all_options! scope, options

      @options[scope] = options
    end

    def get(scope, option)
      validate_scope! scope
      validate_option! scope, option

      default_option = DEFAULTS[option]
      @options[scope][option] ||= default_option ? default_option.call : nil
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
