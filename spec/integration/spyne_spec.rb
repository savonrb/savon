require 'spec_helper'

describe 'Integration with a Spyne.io service' do

  subject(:client) { Savon.new fixture('wsdl/spyne') }

  let(:service_name) { :HelloWorldService }
  let(:port_name)    { :Application }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'HelloWorldService' => {
        ports: {
          'Application' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'http://localhost:8000/'
          }
        }
      }
    )
  end

  it 'knows operations with attributes and attribute groups' do
    operation = client.operation(service_name, port_name, 'say_hello')

    expect(operation.soap_action).to eq('say_hello')
    expect(operation.endpoint).to eq('http://localhost:8000/')

    expect(operation.body_parts).to eq([
      [['say_hello'], { namespace: 'spyne.examples.hello', form: 'qualified', singular: true }]
    ])
  end

  it 'creates an example body with attributes' do
    operation = client.operation(service_name, port_name, :say_hello)
    expect(operation.example_body).to eq(say_hello: {})
  end

  it 'creates a request with attributes' do
    operation = client.operation(service_name, port_name, :say_hello)

    operation.body = { say_hello: {} }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="spyne.examples.hello"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header>
        </env:Header>
        <env:Body>
          <lol0:say_hello/>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
