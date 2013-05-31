require 'spec_helper'

describe Wasabi do
  context 'with: awse.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:awse).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'AWSECommerceService' => {
          ports: {
            'AWSECommerceServicePort' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.com/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortCA' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.ca/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortCN' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.cn/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortDE' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.de/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortFR' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.fr/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortIT' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.it/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortJP' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.co.jp/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortUK' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.co.uk/onca/soap?Service=AWSECommerceService'
            },
            'AWSECommerceServicePortUS' => {
              type: 'http://schemas.xmlsoap.org/wsdl/soap/',
              location: 'https://webservices.amazon.com/onca/soap?Service=AWSECommerceService'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      service, port = 'AWSECommerceService', 'AWSECommerceServicePort'
      operation = wsdl.operation(service, port, 'CartAdd')

      expect(operation.soap_action).to eq('http://soap.amazon.com/CartAdd')
      expect(operation.endpoint).to eq('https://webservices.amazon.com/onca/soap?Service=AWSECommerceService')

      expect(operation.input.count).to eq(1)

      namespace = 'http://webservices.amazon.com/AWSECommerceService/2011-08-01'

      expect(operation.input.first.to_a).to eq([
        [['CartAdd'],                                               { namespace: namespace, form: 'qualified', singular: true }],
        [['CartAdd', 'MarketplaceDomain'],                          { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'AWSAccessKeyId'],                             { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'AssociateTag'],                               { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Validate'],                                   { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'XMLEscaping'],                                { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared'],                                     { namespace: namespace, form: 'qualified', singular: true }],
        [['CartAdd', 'Shared', 'CartId'],                           { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'HMAC'],                             { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'MergeCart'],                        { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'Items'],                            { namespace: namespace, form: 'qualified', singular: true }],
        [['CartAdd', 'Shared', 'Items', 'Item'],                    { namespace: namespace, form: 'qualified', singular: false }],
        [['CartAdd', 'Shared', 'Items', 'Item', 'ASIN'],            { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'Items', 'Item', 'OfferListingId'],  { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'Items', 'Item', 'Quantity'],        { namespace: namespace, form: 'qualified', singular: true, type: 'xs:positiveInteger' }],
        [['CartAdd', 'Shared', 'Items', 'Item', 'AssociateTag'],    { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'Items', 'Item', 'ListItemId'],      { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Shared', 'ResponseGroup'],                    { namespace: namespace, form: 'qualified', singular: false, type: 'xs:string' }],
        [['CartAdd', 'Request'],                                    { namespace: namespace, form: 'qualified', singular: false }],
        [['CartAdd', 'Request', 'CartId'],                          { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'HMAC'],                            { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'MergeCart'],                       { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'Items'],                           { namespace: namespace, form: 'qualified', singular: true }],
        [['CartAdd', 'Request', 'Items', 'Item'],                   { namespace: namespace, form: 'qualified', singular: false }],
        [['CartAdd', 'Request', 'Items', 'Item', 'ASIN'],           { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'Items', 'Item', 'OfferListingId'], { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'Items', 'Item', 'Quantity'],       { namespace: namespace, form: 'qualified', singular: true, type: 'xs:positiveInteger' }],
        [['CartAdd', 'Request', 'Items', 'Item', 'AssociateTag'],   { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'Items', 'Item', 'ListItemId'],     { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }],
        [['CartAdd', 'Request', 'ResponseGroup'],                   { namespace: namespace, form: 'qualified', singular: false, type: 'xs:string' }]
      ])
    end

  end
end
