require 'spec_helper'

describe 'Integration with stockquote.xml' do

  subject(:client) { Savon.new fixture('wsdl/stockquote') }

  let(:service) { :StockQuote }
  let(:port)    { :StockQuoteSoap }

  it 'returns the result in a CDATA tag' do
    operation = client.operation(service, port, :GetQuote)

    # Check the example request.
    expect(operation.example_request).to eq(
      GetQuote: {
        symbol: 'string'
      }
    )

    # Actual message to send.
    message = {
      GetQuote: {
        symbol: 'AAPL'
      }
    }

    # Build a raw request.
    actual = Nokogiri.XML operation.build(message: message)

    # The expected request.
    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://www.webserviceX.NET/"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:GetQuote>
            <lol0:symbol>AAPL</lol0:symbol>
          </lol0:GetQuote>
        </env:Body>
      </env:Envelope>
    })

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

end
