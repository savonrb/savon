require 'spec_helper'

describe Savon::Operation do

  subject(:operation)  { Savon::Operation.new(wsdl_operation, wsdl, http_mock) }

  let(:wsdl)           { Savon::WSDL.new fixture('wsdl/temperature'), http_mock }
  let(:wsdl_operation) { wsdl.operation('ConvertTemperature', 'ConvertTemperatureSoap12', 'ConvertTemp') }

  describe '#endpoint' do
    it 'returns the SOAP endpoint' do
      expect(operation.endpoint).to eq('http://www.webservicex.net/ConvertTemperature.asmx')
    end

    it 'can be overwritten' do
      operation.endpoint = 'http://example.com'
      expect(operation.endpoint).to eq('http://example.com')
    end
  end

  describe '#soap_version' do
    it 'returns the SOAP version determined by the service and port' do
      expect(operation.soap_version).to eq('1.2')
    end

    it 'can be overwritten' do
      operation.soap_version = '1.1'
      expect(operation.soap_version).to eq('1.1')
    end
  end

  describe '#soap_action' do
    it 'returns the SOAP action for the operation' do
      expect(operation.soap_action).to eq('http://www.webserviceX.NET/ConvertTemp')
    end

    it 'can be overwritten' do
      operation.soap_action = 'ConvertSomething'
      expect(operation.soap_action).to eq('ConvertSomething')
    end
  end

  describe '#encoding' do
    it 'defaults to UTF-8' do
      expect(operation.encoding).to eq('UTF-8')
    end

    it 'can be overwritten' do
      operation.encoding = 'US-ASCII'
      expect(operation.encoding).to eq('US-ASCII')
    end
  end

  describe '#headers' do
    it 'returns a Hash of HTTP headers for a SOAP 1.2 operation' do
      expect(operation.headers).to eq(
        'SOAPAction'   => '"http://www.webserviceX.NET/ConvertTemp"',
        'Content-Type' => 'application/soap+xml;charset=UTF-8'
      )
    end

    it 'returns a Hash of HTTP headers for a SOAP 1.1 operation' do
      wsdl_operation = wsdl.operation('ConvertTemperature', 'ConvertTemperatureSoap', 'ConvertTemp')
      operation = Savon::Operation.new(wsdl_operation, wsdl, http_mock)

      expect(operation.headers).to eq(
        'SOAPAction'   => '"http://www.webserviceX.NET/ConvertTemp"',
        'Content-Type' => 'text/xml;charset=UTF-8'
      )
    end

    it 'can be overwritten' do
      header = { 'SecretToken' => 'abc'}
      operation.headers = header

      expect(operation.headers).to eq(header)
    end
  end

  describe '#example_request' do
    it 'returns an example request Hash following Savon‘s conventions' do
      expect(operation.example_request).to eq(
        ConvertTemp: {
          Temperature: 'double',
          FromUnit: 'string',
          ToUnit: 'string'
        }
      )
    end
  end

  describe '#build' do
    it 'returns an example request Hash following Savon‘s conventions' do
      request = operation.build(
        message: {
          ConvertTemp: {
            Temperature: 30,
            FromUnit: 'degreeCelsius',
            ToUnit: 'degreeFahrenheit'
          }
        }
      )

      expected = Nokogiri.XML(%{
        <env:Envelope
            xmlns:lol0="http://www.webserviceX.NET/"
            xmlns:env="http://www.w3.org/2003/05/soap-envelope">
          <env:Header/>
          <env:Body>
            <lol0:ConvertTemp>
              <lol0:Temperature>30</lol0:Temperature>
              <lol0:FromUnit>degreeCelsius</lol0:FromUnit>
              <lol0:ToUnit>degreeFahrenheit</lol0:ToUnit>
            </lol0:ConvertTemp>
          </env:Body>
        </env:Envelope>
      })

      expect(request).to be_equivalent_to(expected).respecting_element_order
    end
  end

  describe '#call' do
    it 'calls the operation with a Hash of options and returns a Response' do
      http_mock.fake_request('http://www.webservicex.net/ConvertTemperature.asmx')

      response = operation.call(
        message: {
          ConvertTemp: {
            Temperature: 30,
            FromUnit: 'degreeCelsius',
            ToUnit: 'degreeFahrenheit'
          }
        }
      )

      expect(response).to be_a(Savon::Response)
    end
  end

end
