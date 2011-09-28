module Savon
  module Hooks

    # = Savon::Hooks::Hook
    #
    # A hook used somewhere in the system.
    class Hook

      HOOKS = [

        # Replaces the POST request executed to call a service.
        # See: Savon::SOAP::Request#response
        #
        # Receives the <tt>Savon::SOAP::Request</tt> and is expected to return an <tt>HTTPI::Response</tt>.
        # It can change the request and return something falsy to still execute the POST request.
        :soap_request

      ]

      # Expects an +id+, the name of the +hook+ to use and a +block+ to be called.
      def initialize(id, hook, &block)
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
