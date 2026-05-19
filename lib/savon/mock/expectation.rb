# frozen_string_literal: true

require "httpi"
require "savon/transport/response"

module Savon
  # A single test expectation set up by Savon's mock interface.
  # One expectation covers one operation call in one test.
  #
  # Records the expected operation name and message, captures what was
  # actually called, and either returns a synthetic response or raises
  # an error on mismatch.
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
      response = { :code => 200, :headers => {}, :body => response } if response.is_a?(String)
      @response = response
      self
    end

    def actual(operation_name, _builder, _globals, locals)
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

    # Builds and returns a Transport::Response from the configured response hash.
    #
    # @return [Transport::Response]
    # @raise  [ExpectationError] if no response was configured for this expectation
    def response!
      unless @response
        raise ExpectationError, "This expectation was not set up with a response."
      end

      Transport::Response.new(@response[:code], @response[:headers], @response[:body])
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
      # === allows RSpec matchers (e.g. include(:key)) to be used as expected values
      return true if msg_expected === msg_real # rubocop:disable Style/CaseEquality
      return false if msg_expected.nil? || msg_real.nil? # If both are nil has returned true

      msg_expected.each do |key, expected_value|
        next if expected_value == :any && msg_real.include?(key)
        return false if expected_value != msg_real[key]
      end
      true
    end
  end
end
