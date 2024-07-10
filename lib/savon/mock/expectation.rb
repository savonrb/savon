# frozen_string_literal: true
require "faraday"

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
      env = Faraday::Env.from(status: @response[:code], response_headers: @response[:headers], response_body: @response[:body])
      Faraday::Response.new(env)
    end

    private

    def verify_operation_name!
      unless @expected[:operation_name] == @actual[:operation_name]
        raise ExpectationError, "Expected a request to the #{@expected[:operation_name].inspect} operation.\n" \
                                "Received a request to the #{@actual[:operation_name].inspect} operation instead."
      end
    end

    def verify_message!
      return if @expected[:message].eql? :any
      unless equals_except_any(@expected[:message], @actual[:message])
        expected_message = "  with this message: #{@expected[:message].inspect}" if @expected[:message]
        expected_message ||= "  with no message."

        actual_message = "  with this message: #{@actual[:message].inspect}" if @actual[:message]
        actual_message ||= "  with no message."

        raise ExpectationError, "Expected a request to the #{@expected[:operation_name].inspect} operation\n#{expected_message}\n" \
        "Received a request to the #{@actual[:operation_name].inspect} operation\n#{actual_message}"
      end
    end

    def equals_except_any(msg_expected, msg_real)
      return true if msg_expected === msg_real
      return false if (msg_expected.nil? || msg_real.nil?) # If both are nil has returned true
      msg_expected.each do |key, expected_value|
        next if (expected_value == :any &&  msg_real.include?(key))
        return false if expected_value != msg_real[key]
      end
      true
    end
  end
end
