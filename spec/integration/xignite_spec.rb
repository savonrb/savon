require 'spec_helper'

describe 'Integration with Xignite' do

  # reference: http://www.xignite.com/product/global-security-master-data/api/GetSecurities/
  subject(:client) { Savon.new fixture('wsdl/xignite') }

  let(:service_name) { :XigniteGlobalMaster }
  let(:port_name)    { :XigniteGlobalMasterSoap12 }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'XigniteGlobalMaster' => {
        ports: {
          'XigniteGlobalMasterSoap' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'http://globalmaster.xignite.com/xglobalmaster.asmx'
          },
          'XigniteGlobalMasterSoap12' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap12/',
            location: 'http://globalmaster.xignite.com/xglobalmaster.asmx'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    operation = client.operation(service_name, port_name, :GetSecurities)

    expect(operation.soap_action).to eq('http://www.xignite.com/services/GetSecurities')
    expect(operation.endpoint).to eq('http://globalmaster.xignite.com/xglobalmaster.asmx')

    namespace = 'http://www.xignite.com/services/'

    expect(operation.body_parts).to eq([
      [['GetSecurities'],                   { namespace: namespace, form: 'qualified', singular: true }],
      [['GetSecurities', 'Identifiers'],    { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
      [['GetSecurities', 'IdentifierType'], { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
      [['GetSecurities', 'AsOfDate'],       { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }]
    ])
  end

  it 'creates an example header' do
    operation = client.operation(service_name, port_name, :GetSecurities)

    expect(operation.example_header).to eq(
      Header: {
        Username: 'string',
        Password: 'string',
        Tracer: 'string'
      }
    )
  end

  it 'creates an example body' do
    operation = client.operation(service_name, port_name, :GetSecurities)

    expect(operation.example_body).to eq(
      GetSecurities: {
        Identifiers: 'string',
        IdentifierType: 'string',
        AsOfDate: 'string'
      }
    )
  end

  it 'creates a request with a header' do
    operation = client.operation(service_name, port_name, :GetSecurities)

    operation.header = {
      Header: {
        Username: 'test',
        Password: 'secret',
        Tracer: 'i-dont-know'
      }
    }

    operation.body = {
      GetSecurities: {
        Identifiers: 'NESN.XVTX,BMW.XETR',
        IdentifierType: 'Symbol',
        AsOfDate: '6/4/2013'
      }
    }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://www.xignite.com/services/"
          xmlns:env="http://www.w3.org/2003/05/soap-envelope">
        <env:Header>
          <lol0:Header>
            <lol0:Username>test</lol0:Username>
            <lol0:Password>secret</lol0:Password>
            <lol0:Tracer>i-dont-know</lol0:Tracer>
          </lol0:Header>
        </env:Header>
        <env:Body>
          <lol0:GetSecurities>
            <lol0:Identifiers>NESN.XVTX,BMW.XETR</lol0:Identifiers>
            <lol0:IdentifierType>Symbol</lol0:IdentifierType>
            <lol0:AsOfDate>6/4/2013</lol0:AsOfDate>
          </lol0:GetSecurities>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
