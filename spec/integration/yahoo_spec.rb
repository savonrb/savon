require 'spec_helper'

describe 'Integration with Yahoo\'s AccountService' do

  subject(:client) { Savon.new fixture('wsdl/yahoo') }

  let(:service_name) { :AccountServiceService }
  let(:port_name)    { :AccountService }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'AccountServiceService' => {
        ports: {
          'AccountService' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',

            # symbolic endpoint
            location: 'https://USE_ADDRESS_RETURNED_BY_LOCATION_SERVICE/services/V10/AccountService'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    operation = client.operation(service_name, port_name, :updateStatusForManagedPublisher)

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('https://USE_ADDRESS_RETURNED_BY_LOCATION_SERVICE/services/V10/AccountService')

    namespace = 'http://apt.yahooapis.com/V10'

    expect(operation.body_parts).to eq([
      [['updateStatusForManagedPublisher'],                  { namespace: namespace, form: 'qualified', singular: true }],
      [['updateStatusForManagedPublisher', 'accountID'],     { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }],
      [['updateStatusForManagedPublisher', 'accountStatus'], { namespace: namespace, form: 'qualified', singular: true, type: 'xsd:string' }]
    ])
  end

  # multiple implicit headers. reference: http://www.ibm.com/developerworks/library/ws-tip-headers/index.html
  it 'creates an example header' do
    operation = client.operation(service_name, port_name, :updateStatusForManagedPublisher)

    expect(operation.example_header).to eq(
      Security: {
        UsernameToken: {
          Username: 'string',
          Password: 'string'
        }
      },
      license: 'string',
      accountID: 'string'
    )
  end

  it 'creates an example body' do
    operation = client.operation(service_name, port_name, :updateStatusForManagedPublisher)

    expect(operation.example_body).to eq(
      updateStatusForManagedPublisher: {
        accountID: 'string',
        accountStatus: 'string'
      }
    )
  end

  it 'creates a request with multiple headers' do
    operation = client.operation(service_name, port_name, :updateStatusForManagedPublisher)

    operation.header = {
      Security: {
        UsernameToken: {
          Username: 'admin',
          Password: 'secret'
        }
      },
      license: 'abc-license',
      accountID: '23'
    }

    operation.body = {
      updateStatusForManagedPublisher: {
        accountID: '23',
        accountStatus: 'closed'
      }
    }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://schemas.xmlsoap.org/ws/2002/07/secext"
          xmlns:lol1="http://apt.yahooapis.com/V10"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header>
          <lol0:Security>
            <UsernameToken>
              <Username>admin</Username>
              <Password>secret</Password>
            </UsernameToken>
          </lol0:Security>
          <lol1:license>abc-license</lol1:license>
          <lol1:accountID>23</lol1:accountID>
        </env:Header>
        <env:Body>
          <lol1:updateStatusForManagedPublisher>
            <lol1:accountID>23</lol1:accountID>
            <lol1:accountStatus>closed</lol1:accountStatus>
          </lol1:updateStatusForManagedPublisher>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
