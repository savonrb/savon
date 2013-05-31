require 'spec_helper'

describe Wasabi do
  context 'with: amazon.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:amazon).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'AmazonFPS' => {
          :ports => {
            'AmazonFPSPort' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'https://fps.amazonaws.com'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      service, port = 'AmazonFPS', 'AmazonFPSPort'
      operation = wsdl.operation(service, port, 'Pay')

      expect(operation.soap_action).to eq('Pay')
      expect(operation.endpoint).to eq('https://fps.amazonaws.com')

      expect(operation.input.count).to eq(1)

      namespace = 'http://fps.amazonaws.com/doc/2008-09-17/'

      expect(operation.input.first.to_a).to eq([
        [['Pay'],                                           { namespace: namespace, form: 'qualified', singular: true }],
        [['Pay', 'SenderTokenId'],                          { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'RecipientTokenId'],                       { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'TransactionAmount'],                      { namespace: namespace, form: 'qualified', singular: true }],
        [['Pay', 'TransactionAmount', 'CurrencyCode'],      { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'TransactionAmount', 'Value'],             { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'ChargeFeeTo'],                            { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'CallerReference'],                        { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'CallerDescription'],                      { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'SenderDescription'],                      { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'DescriptorPolicy'],                       { namespace: namespace, form: 'qualified', singular: true }],
        [['Pay', 'DescriptorPolicy', 'SoftDescriptorType'], { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'DescriptorPolicy', 'CSOwner'],            { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'TransactionTimeoutInMins'],               { namespace: namespace, form: 'qualified', singular: true, type: 'xs:integer' }],
        [['Pay', 'MarketplaceFixedFee'],                    { namespace: namespace, form: 'qualified', singular: true }],
        [['Pay', 'MarketplaceFixedFee', 'CurrencyCode'],    { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'MarketplaceFixedFee', 'Value'],           { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['Pay', 'MarketplaceVariableFee'],                 { namespace: namespace, form: 'qualified', singular: true, type: 'xs:decimal' }]
      ])
    end

  end
end
