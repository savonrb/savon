require 'spec_helper'

describe 'Integration with Jetairways\'s SessionCreate Service' do

  subject(:client) { Savon.new fixture('wsdl/jetairways') }



  let(:service_name) { :SessionCreate }
  let(:port_name)    { :SessionCreateSoap }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
     'SessionCreate'=> {
       :ports=> {
         'SessionCreateSoap'=> {
            :type=>'http://schemas.xmlsoap.org/wsdl/soap/',
            # symbolic endpoint
            :location=>'http://USE_ADDRESS_RETURNED_BY_LOCATION_SERVICE/jettaobeapi/SessionCreate.asmx'
         },
         'SessionCreateSoap12'=>{
           :type=>'http://schemas.xmlsoap.org/wsdl/soap12/',
            # symbolic endpoint
           :location=>'http://USE_ADDRESS_RETURNED_BY_LOCATION_SERVICE/jettaobeapi/SessionCreate.asmx'
         }
       }
     }
    )
  end

  it 'knows the operations' do
    operation = client.operation(service_name, port_name, :Logon)

    expect(operation.soap_action).to eq('http://www.vedaleon.com/webservices/Logon')
    expect(operation.endpoint).to eq('https://USE_ADDRESS_RETURNED_BY_LOCATION_SERVICE/jettaobeapi/SessionCreate.asmx')

    namespace = 'http://www.vedaleon.com/webservices'

    expect(operation.body_parts).to eq([
      [['Logon'], { namespace: namespace, form: 'qualified', singular: true }]
    ])
  end

  # multiple implicit headers. reference: http://www.ibm.com/developerworks/library/ws-tip-headers/index.html
  it 'creates an example header' do
    operation = client.operation(service_name, port_name, :Logon)

    expect(operation.example_header).to eq(
      MessageHeader:
        {From: {PartyId: [{}], Role: 'string'},
         To: {PartyId: [{}], Role: 'string'},
         CPAId: 'string',
         ConversationId: 'string',
         Service: {},
         Action: 'string',
         MessageData:
          {MessageId: 'string',
           Timestamp: 'string',
           RefToMessageId: 'string',
           TimeToLive: 'dateTime'},
         DuplicateElimination: {},
         Description: [{}],
         _id: 's:ID',
         _version: 's:string'},
       Security:
        {UsernameToken:
          {Username: 'string',
           Password: 'string',
           Organization: 'string',
           Domain: 'string'},
         BinarySecurityToken: 'string'}
    )
  end

  it 'creates an example body' do
    operation = client.operation(service_name, port_name, :updateStatusForManagedPublisher)

    expect(operation.example_body).to eq(
                    Logon:{}
    )
  end

  it 'creates a request with multiple headers' do
    operation = client.operation(service_name, port_name, :Logon)

    operation.header =
    {
    MessageHeader:
      {CPAId:"9W",
       ConversationId:"1",
       Service:{Service:"Create"},
       Action:"CreateSession",
       MessageData:
        {MessageId:"0",
         Timestamp:"2014-02-01T12:57:12.000Z"}
      },
      Security:
      { UsernameToken: {
          Username: 'example_user',
          Password: 'my_secret',
          Organization: 'example_organization'}

       }
    }
    operation.body =
    {Logon:{}}

    expected = Nokogiri.XML('
      <env:Envelope
       xmlns:lol0="http://www.ebxml.org/namespaces/messageHeader"
       xmlns:lol1="http://schemas.xmlsoap.org/ws/2002/12/secext"
       xmlns:lol2="http://www.vedaleon.com/webservices"
       xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header>
          <lol0:MessageHeader>
            <lol0:CPAId>9W</lol0:CPAId>
            <lol0:ConversationId>1</lol0:ConversationId>
            <lol0:Service>Create</lol0:Service>
            <lol0:Action>CreateSession</lol0:Action>
            <lol0:MessageData>
              <lol0:MessageId>0</lol0:MessageId>
              <lol0:Timestamp>2014-02-01T12:57:12.000Z</lol0:Timestamp>
            </lol0:MessageData>
          </lol0:MessageHeader>
          <lol1:Security>
            <lol1:UsernameToken>
              <lol1:Username>example_user</lol1:Username>
              <lol1:Password>my_secret</lol1:Password>
              <lol1:Organization>example_organization</lol1:Organization>
            </lol1:UsernameToken>
          </lol1:Security>
        </env:Header>
        <env:Body>
          <lol2:Logon/>
        </env:Body>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
