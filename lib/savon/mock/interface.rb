require "savon/mock/expectation"

module Savon
  module MockInterface

    def mock!
      @mock = true
    end

    def mocked?
      @mock
    end

    def unmock!
      @mock = false
    end

    def expects(operation_name)
      expectation = MockExpectation.new(operation_name)
      expectations << expectation
      expectation
    end

    def expected_request(operation_name, builder, globals, locals)
      expectation = expectations.shift

      if expectation
        expectation.record!(operation_name, builder, globals, locals)

        expectation.verify!
        expectation.response!
      else
        raise ExpectationError, "Unexpected request to the #{operation_name.inspect} operation."
      end
    end

    def verify!
      return if @expectations.empty?
      @expectations.each(&:verify!)
    ensure
      @expectations = nil
    end

    def expectations
      @expectations ||= []
    end

  end
end
