class Wasabi

  Error = Class.new(StandardError)

  HTTPError = Class.new(Error) do

    def initialize(message, response = nil)
      super(message)
      @response = response
    end

    attr_reader :response

  end

end
