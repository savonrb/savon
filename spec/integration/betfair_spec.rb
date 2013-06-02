require 'spec_helper'

describe 'Integration with Betfair' do

  subject(:client) { Savon.new fixture('wsdl/betfair') }

  let(:service_name) { :BFExchangeService }
  let(:port_name)    { :BFExchangeService }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'BFExchangeService' => {
        :ports => {
          'BFExchangeService' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'https://api.betfair.com/exchange/v5/BFExchangeService'
          }
        }
      }
    )
  end

  it 'knows operations with extensions and Arrays' do
    service = port = 'BFExchangeService'
    operation = client.operation(service, port, 'getMUBetsLite')

    expect(operation.soap_action).to eq('getMUBetsLite')
    expect(operation.endpoint).to eq('https://api.betfair.com/exchange/v5/BFExchangeService')

    ns = 'http://www.betfair.com/publicapi/v5/BFExchangeService/'
    ns2 = 'http://www.betfair.com/publicapi/types/exchange/v5/'

    expect(operation.input_parts).to eq([
      [['getMUBetsLite'],
        { namespace: ns, form: 'qualified',   singular: true }],

      [['getMUBetsLite', 'request'],
        { namespace: ns, form: 'qualified',   singular: true }],

      # extension elements

      [['getMUBetsLite', 'request', 'header'],
         { namespace: ns2, form: 'unqualified', singular: true }],

      [['getMUBetsLite', 'request', 'header', 'clientStamp'],
         { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:long' }],

      [['getMUBetsLite', 'request', 'header', 'sessionToken'],
         { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:string' }],

      # ---

      [['getMUBetsLite', 'request', 'betStatus'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:string' }],

      [['getMUBetsLite', 'request', 'marketId'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:int' }],

      [['getMUBetsLite', 'request', 'betIds'],
        { namespace: ns2, form: 'unqualified', singular: true }],

      [['getMUBetsLite', 'request', 'betIds', 'betId'],
        { namespace: ns2, form: 'qualified',   singular: false, type: 'xsd:long' }],

      [['getMUBetsLite', 'request', 'orderBy'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:string' }],

      [['getMUBetsLite', 'request', 'sortOrder'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:string' }],

      [['getMUBetsLite', 'request', 'recordCount'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:int' }],

      [['getMUBetsLite', 'request', 'startRecord'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:int' }],

      [['getMUBetsLite', 'request', 'matchedSince'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:dateTime' }],

      [['getMUBetsLite', 'request', 'excludeLastSecond'],
        { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:boolean' }]
    ])
  end

  it 'creates a proper example request for messages with Arrays' do
    operation = client.operation(service_name, port_name, :getMUBetsLite)

    expect(operation.example_body).to eq(
      getMUBetsLite: {
        request: {

          # This is an extension
          header: {
            clientStamp: 'long',
            sessionToken: 'string'
          },

          betStatus: 'string',
          marketId: 'int',
          betIds: {

            # This is an Array of simpleTypes
            betId: ['long']

          },
          orderBy: 'string',
          sortOrder: 'string',
          recordCount: 'int',
          startRecord: 'int',
          matchedSince: 'dateTime',
          excludeLastSecond: 'boolean'
        }
      }
    )
  end

  it 'builds a request for extensions and Arrays' do
    operation = client.operation(service_name, port_name, :getMUBetsLite)
    datetime_value = (Time.now - 365).xmlschema

    operation.body = {
      getMUBetsLite: {
        request: {
          header: {
            clientStamp: 'test',
            sessionToken: 'token'
          },
          betStatus: 'U',
          marketId: 1,
          betIds: {
            betId: [1, 2, 3]
          },
          orderBy: 'NONE',
          sortOrder: 'DESC',
          recordCount: 10,
          startRecord: 1,
          matchedSince: datetime_value,
          excludeLastSecond: true
        }
      }
    }

    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://www.betfair.com/publicapi/v5/BFExchangeService/"
          xmlns:lol1="http://www.betfair.com/publicapi/types/exchange/v5/"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:getMUBetsLite>
            <lol0:request>
              <header>
                <clientStamp>test</clientStamp>
                <sessionToken>token</sessionToken>
              </header>
              <betStatus>U</betStatus>
              <marketId>1</marketId>
              <betIds>
                <lol1:betId>1</lol1:betId>
                <lol1:betId>2</lol1:betId>
                <lol1:betId>3</lol1:betId>
              </betIds>
              <orderBy>NONE</orderBy>
              <sortOrder>DESC</sortOrder>
              <recordCount>10</recordCount>
              <startRecord>1</startRecord>
              <matchedSince>#{datetime_value}</matchedSince>
              <excludeLastSecond>true</excludeLastSecond>
            </lol0:request>
          </lol0:getMUBetsLite>
        </env:Body>
      </env:Envelope>
    })

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
