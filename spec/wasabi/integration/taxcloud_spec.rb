require 'spec_helper'

describe Wasabi do
  context 'with: taxcloud.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:taxcloud).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'TaxCloud' => {
          :ports => {
            'TaxCloudSoap' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'https://api.taxcloud.net/1.0/TaxCloud.asmx'
            },
            'TaxCloudSoap12' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap12/',
              :location => 'https://api.taxcloud.net/1.0/TaxCloud.asmx'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      service, port = 'TaxCloud', 'TaxCloudSoap'
      operation = wsdl.operation(service, port, 'VerifyAddress')

      expect(operation.soap_action).to eq('http://taxcloud.net/VerifyAddress')
      expect(operation.endpoint).to eq('https://api.taxcloud.net/1.0/TaxCloud.asmx')

      expect(operation.input.count).to eq(1)

      namespace = 'http://taxcloud.net'

      expect(operation.input.first.to_a).to eq([
        [['VerifyAddress'],               { namespace: namespace, form: 'qualified', singular: true }],
        [['VerifyAddress', 'uspsUserID'], { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyAddress', 'address1'],   { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyAddress', 'address2'],   { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyAddress', 'city'],       { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyAddress', 'state'],      { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyAddress', 'zip5'],       { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['VerifyAddress', 'zip4'],       { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }]
      ])
    end

  end
end
