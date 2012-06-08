module Savon
  module Hooks

    # = Savon::Hooks::Hook
    #
    # A hook used somewhere in the system.
    class Hook

      HOOKS = [

        # :soap_request
        #
        # Around filter wrapping the POST request executed to call a SOAP service.
        # See: Savon::SOAP::Request#response
        #
        # Arguments
        #
        #   [callback] A block to execute the SOAP request
        #   [request]  The current <tt>Savon::SOAP::Request</tt>
        #
        # Examples
        #
        #   Log the time before and after the SOAP call:
        #
        #     Savon.config.hooks.define(:my_hook, :soap_request) do |callback, request|
        #       Timer.log(:start, Time.now)
        #       response = callback.call
        #       Timer.log(:end, Time.now)
        #       response
        #     end
        #
        #   Replace the SOAP call and return a custom response:
        #
        #     Savon.config.hooks.define(:mock_hook, :soap_request) do |_, request|
        #       HTTPI::Response.new(200, {}, "")
        #     end
        :soap_request

      ]

      # Expects an +id+, the name of the +hook+ to use and a +block+ to be called.
      def initialize(id, hook, &block)
        unless HOOKS.include?(hook)
          raise ArgumentError, "No such hook: #{hook}. Expected one of: #{HOOKS.join(', ')}"
        end

        self.id = id
        self.hook = hook
        self.block = block
      end

      attr_accessor :id, :hook, :block

      # Calls the +block+ with the given +args+.
      def call(*args)
        block.call(*args)
      end

    end
  end
end
