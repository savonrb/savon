require "httpi"

module Savon
  class MockExpectation

    def initialize(operation_name)
      @expected = { :operation_name => operation_name }
      @actual = nil
    end

    def with(locals)
      @expected[:message] = locals[:message]
      self
    end

    def returns(response)
      response = { :code => 200, :headers => {}, :body => response } if response.kind_of?(String)
      @response = response
      self
    end

    def actual(operation_name, builder, globals, locals)
      @actual = {
        :operation_name => operation_name,
        :message        => locals[:message]
      }
    end

    def verify!
      unless @actual
        raise ExpectationError, "Expected a request to the #{@expected[:operation_name].inspect} operation, " \
                                "but no request was executed."
      end

      verify_operation_name!
      verify_message!
    end

    def response!
      unless @response
        raise ExpectationError, "This expectation was not set up with a response."
      end

      HTTPI::Response.new(@response[:code], @response[:headers], @response[:body])
    end

    private

    def verify_operation_name!
      unless @expected[:operation_name] == @actual[:operation_name]
        raise ExpectationError, "Expected a request to the #{@expected[:operation_name].inspect} operation.\n" \
                                "Received a request to the #{@actual[:operation_name].inspect} operation instead."
      end
    end

    def verify_message!
      unless @expected[:message] == @actual[:message]
        expected_message = "  with this message: #{@expected[:message].inspect}" if @expected[:message]
        expected_message ||= "  with no message."

        actual_message = "  with this message: #{@actual[:message].inspect}" if @actual[:message]
        actual_message ||= "  with no message."

        raise ExpectationError, "Expected a request to the #{@expected[:operation_name].inspect} operation\n#{expected_message}\n" \
                                "Received a request to the #{@actual[:operation_name].inspect} operation\n#{actual_message}"
      end
    end

  end
end
