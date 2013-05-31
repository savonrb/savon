require 'spec_helper'

describe 'Integration with betfair.xml' do

  subject(:client) { Savon.new fixture('wsdl/betfair') }

  it 'creates a proper example request for messages with Arrays' do
    service = port = :BFExchangeService
    operation = client.operation(service, port, :getMUBetsLite)

    # Check the example request.
    expect(operation.example_request).to eq(
      getMUBetsLite: {
        request: {

          # This is an extension.
          header: {
            clientStamp: 'long',
            sessionToken: 'string'
          },

          betStatus: 'string',
          marketId: 'int',
          betIds: {

            # This is an Array of simpleTypes.
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

    datetime_value = (Time.now - 365).xmlschema

    # Build a raw request.
    actual = Nokogiri.XML operation.build(
      message: {
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
    )

    # The expected request.
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

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

end
