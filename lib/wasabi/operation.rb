class Wasabi
  class Operation

    def initialize(options = {})
      @soap_action = options[:soap_action]
      @input       = options[:input]
      @nsid        = options[:nsid]
    end

    attr_reader :soap_action, :input, :nsid

    # XXX: legacy interface
    def [](key)
      case key
      when :action               then @soap_action
      when :input                then @input
      when :namespace_identifier then @nsid
      end
    end

  end
end
