# frozen_string_literal: true
require 'spec_helper'

describe Savon::InvalidResponseError do
  let(:invalid_response_error) do
    Savon::InvalidResponseError.new(http_response, xml)
  end
  let(:http_response) { new_response(code: 200, body: 'invalid xml body') }
  let(:xml)           { 'invalid xml body' }
  let(:error_message) { "Unable to parse response body:\n\"invalid xml body\"" }

  it 'inherits from Savon::Error' do
    expect(Savon::InvalidResponseError.ancestors).to include(Savon::Error)
  end

  describe '#http' do
    it 'returns the HTTPI::Response' do
      expect(invalid_response_error.http).to be_a(HTTPI::Response)
    end
  end

  describe '#xml' do
    it 'returns the xml body' do
      expect(invalid_response_error.xml).to eq xml
    end
  end

  %i(message to_s).each do |method|
    describe "##{method}" do
      it 'returns the specified error message' do
        expect(invalid_response_error.send(method)).to eq(error_message)
      end

      context 'when the xml variable is different' do
        let(:xml)           { 'different than body' }
        let(:error_message) { "Unable to parse response body:\n\"different than body\"" }

        it 'returns the error message with the xml string' do
          expect(invalid_response_error.send(method)).to eq(error_message)
        end
      end
    end
  end

  def new_response(options = {})
    defaults = { code: 200, headers: {}, body: Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end
end
