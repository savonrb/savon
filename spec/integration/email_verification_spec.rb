require 'spec_helper'

describe 'Integration with EmailVerification service' do

  subject(:client) { Savon.new fixture('wsdl/email_verification') }

  let(:service_name) { :EmailVerNoTestEmail }
  let(:port_name)    { :EmailVerNoTestEmailSoap12 }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'EmailVerNoTestEmail' => {
        :ports => {
          'EmailVerNoTestEmailSoap' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx'
          },
          'EmailVerNoTestEmailSoap12' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap12/',
            :location => 'http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx'
          }
        }
      }
    )
  end

  it 'knows the operations' do
    service, port = 'EmailVerNoTestEmail', 'EmailVerNoTestEmailSoap12'
    operation = client.operation(service, port, 'VerifyEmail')

    expect(operation.soap_action).to eq('http://ws.cdyne.com/VerifyEmail')
    expect(operation.endpoint).to eq('http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx')

    namespace = 'http://ws.cdyne.com/'

    expect(operation.input_parts).to eq([
      [['VerifyEmail'],               { namespace: namespace, form: 'qualified', singular: true }],
      [['VerifyEmail', 'email'],      { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
      [['VerifyEmail', 'LicenseKey'], { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }]
    ])
  end

  it 'creates an example request' do
    operation = client.operation(service_name, port_name, :VerifyEmail)

    expect(operation.example_body).to eq(
      VerifyEmail: {
        email: 'string',
        LicenseKey: 'string'
      }
    )
  end

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :VerifyEmail)

    operation.body = {
      VerifyEmail: {
        email: 'soap@example.com',
        LicenseKey: '?'
      }
    }

    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://ws.cdyne.com/"
          xmlns:env="http://www.w3.org/2003/05/soap-envelope">
        <env:Header/>
        <env:Body>
          <lol0:VerifyEmail>
            <lol0:email>soap@example.com</lol0:email>
            <lol0:LicenseKey>?</lol0:LicenseKey>
          </lol0:VerifyEmail>
        </env:Body>
      </env:Envelope>
    })

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
