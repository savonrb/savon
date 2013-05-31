require 'spec_helper'

describe Wasabi do
  context 'with: email_validation.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:email_validation).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
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
      operation = wsdl.operation(service, port, 'VerifyEmail')

      expect(operation.soap_action).to eq('http://ws.cdyne.com/VerifyEmail')
      expect(operation.endpoint).to eq('http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx')

      expect(operation.input.count).to eq(1)

      namespace = 'http://ws.cdyne.com/'

      expect(operation.input.first.to_a).to eq([
        [['VerifyEmail'],               { namespace: namespace, form: 'qualified', singular: true }],
        [['VerifyEmail', 'email'],      { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyEmail', 'LicenseKey'], { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }]
      ])
    end

  end
end
