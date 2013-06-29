require 'spec_helper'

describe 'Integration with Bronto' do

  subject(:client) { Savon.new fixture('wsdl/bronto') }

  let(:service_name) { :BrontoSoapApiImplService }
  let(:port_name)    { :BrontoSoapApiImplPort }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'BrontoSoapApiImplService' => {
        ports: {
          'BrontoSoapApiImplPort' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'https://api.bronto.com/v4'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    operation = client.operation(service_name, port_name, :addLogins)

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('https://api.bronto.com/v4')

    namespace = 'http://api.bronto.com/v4'

    expect(operation.body_parts).to eq([
      [['addLogins'],                                                   { namespace: namespace, form: 'qualified',   singular: true }],
      [['addLogins', 'accounts'],                                       { namespace: namespace, form: 'unqualified', singular: false }],
      [['addLogins', 'accounts', 'username'],                           { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'password'],                           { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation'],                 { namespace: namespace, form: 'unqualified', singular: true }],
      [['addLogins', 'accounts', 'contactInformation', 'organization'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'firstName'],    { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'lastName'],     { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'email'],        { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'phone'],        { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'address'],      { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'address2'],     { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'city'],         { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'state'],        { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'zip'],          { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'country'],      { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'contactInformation', 'notes'],        { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['addLogins', 'accounts', 'permissionAgencyAdmin'],              { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionAdmin'],                    { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionApi'],                      { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionUpgrade'],                  { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionFatigueOverride'],          { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionMessageCompose'],           { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionMessageApprove'],           { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionMessageDelete'],            { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionAutomatorCompose'],         { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionListCreateSend'],           { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionListCreate'],               { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionSegmentCreate'],            { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionFieldCreate'],              { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionFieldReorder'],             { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionSubscriberCreate'],         { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }],
      [['addLogins', 'accounts', 'permissionSubscriberView'],           { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:boolean' }]
    ])
  end

  # explicit headers. reference: http://www.ibm.com/developerworks/library/ws-tip-headers/index.html
  it 'creates an example header' do
    operation = client.operation(service_name, port_name, :addLogins)

    expect(operation.example_header).to eq(
      sessionHeader: {
        sessionId: 'string'
      }
    )
  end

  it 'creates an example body' do
    operation = client.operation(service_name, port_name, :addLogins)

    expect(operation.example_body).to eq(
      addLogins: {
        accounts: [
          {
            username: 'string',
            password: 'string',
            contactInformation: {
              organization: 'string',
              firstName: 'string',
              lastName: 'string',
              email: 'string',
              phone: 'string',
              address: 'string',
              address2: 'string',
              city: 'string',
              state: 'string',
              zip: 'string',
              country: 'string',
              notes: 'string'
            },
            permissionAgencyAdmin: 'boolean',
            permissionAdmin: 'boolean',
            permissionApi: 'boolean',
            permissionUpgrade: 'boolean',
            permissionFatigueOverride: 'boolean',
            permissionMessageCompose: 'boolean',
            permissionMessageApprove: 'boolean',
            permissionMessageDelete: 'boolean',
            permissionAutomatorCompose: 'boolean',
            permissionListCreateSend: 'boolean',
            permissionListCreate: 'boolean',
            permissionSegmentCreate: 'boolean',
            permissionFieldCreate: 'boolean',
            permissionFieldReorder: 'boolean',
            permissionSubscriberCreate: 'boolean',
            permissionSubscriberView: 'boolean'
          }
        ]
      }
    )
  end

  it 'creates a request with a header' do
    operation = client.operation(service_name, port_name, :addLogins)

    operation.header = {
      sessionHeader: {
        sessionId: '23'
      }
    }

    operation.body = {
      addLogins: {
        accounts: [
          {
            username: 'admin',
            password: 'secert',
            contactInformation: {
              firstName: 'brew',
              email: 'brew@example.com',
            },
            permissionApi: true,
          }
        ]
      }
    }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://api.bronto.com/v4"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header>
          <lol0:sessionHeader>
            <sessionId>23</sessionId>
          </lol0:sessionHeader>
        </env:Header>
        <env:Body>
          <lol0:addLogins>
            <accounts>
              <username>admin</username>
              <password>secert</password>
              <contactInformation>
                <firstName>brew</firstName>
                <email>brew@example.com</email>
              </contactInformation>
              <permissionApi>true</permissionApi>
            </accounts>
          </lol0:addLogins>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
