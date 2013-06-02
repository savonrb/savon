require 'spec_helper'

describe 'Integration with Stockquote service' do

  subject(:client) { Savon.new fixture('wsdl/stockquote') }

  let(:service_name) { :StockQuote }
  let(:port_name)    { :StockQuoteSoap }

  it 'creates an example request' do
    operation = client.operation(service_name, port_name, :GetQuote)

    expect(operation.example_request).to eq(
      GetQuote: {
        symbol: 'string'
      }
    )
  end

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :GetQuote)

    request = Nokogiri.XML operation.build(
      message: {
        GetQuote: {
          symbol: 'AAPL'
        }
      }
    )

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

    expect(request).to be_equivalent_to(expected).respecting_element_order
  end

end
