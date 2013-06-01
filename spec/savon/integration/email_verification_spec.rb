require 'spec_helper'

describe 'Integration with EmailVerification service' do

  subject(:client) { Savon.new fixture('wsdl/email_verification') }

  let(:service_name) { :EmailVerNoTestEmail }
  let(:port_name)    { :EmailVerNoTestEmailSoap12 }

  it 'creates an example request' do
    operation = client.operation(service_name, port_name, :VerifyEmail)

    expect(operation.example_request).to eq(
      VerifyEmail: {
        email: 'string',
        LicenseKey: 'string'
      }
    )
  end

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :VerifyEmail)

    request = Nokogiri.XML operation.build(
      message: {
        VerifyEmail: {
          email: 'soap@example.com',
          LicenseKey: '?'
        }
      }
    )

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

    expect(request).to be_equivalent_to(expected).respecting_element_order
  end

end
