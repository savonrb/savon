require 'spec_helper'

describe 'Integration with email_verification.xml' do

  subject(:client) { Savon.new fixture('wsdl/email_verification') }

  let(:service) { :EmailVerNoTestEmail }
  let(:port)    { :EmailVerNoTestEmailSoap12 }

  it 'would validate an Email if we had a license key' do
    operation = client.operation(service, port, :VerifyEmail)

    # Check the example request.
    expect(operation.example_request).to eq(
      VerifyEmail: {
        email: 'string',
        LicenseKey: 'string'
      }
    )

    # Actual message to send.
    message = {
      VerifyEmail: {
        email: 'soap@example.com',
        LicenseKey: '?'
      }
    }

    actual = Nokogiri.XML operation.build(message: message)

    # The expected request.
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

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

end
