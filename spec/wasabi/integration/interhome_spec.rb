require 'spec_helper'

describe Wasabi do
  context 'with: interhome.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:interhome).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'WebService' => {
          :ports => {
            'WebServiceSoap' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'https://webservices.interhome.com/quality/partnerV3/WebService.asmx'
            },
            'WebServiceSoap12' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap12/',
              :location => 'https://webservices.interhome.com/quality/partnerV3/WebService.asmx'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      service, port = 'WebService', 'WebServiceSoap'
      operation = wsdl.operation(service, port, 'ClientBooking')

      expect(operation.soap_action).to eq('http://www.interhome.com/webservice/ClientBooking')
      expect(operation.endpoint).to eq('https://webservices.interhome.com/quality/partnerV3/WebService.asmx')

      expect(operation.input.count).to eq(1)

      namespace = 'http://www.interhome.com/webservice'

      expect(operation.input.first.to_a).to eq([
        [['ClientBooking'],                                    { namespace: namespace, form: 'qualified', singular: true }],
        [['ClientBooking', 'inputValue'],                      { namespace: namespace, form: 'qualified', singular: true }],
        [['ClientBooking', 'inputValue', 'SalesOfficeCode'],   { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'AccommodationCode'], { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],

        [['ClientBooking', 'inputValue', 'AdditionalServices'],
          {namespace: namespace, form: 'qualified', singular: true }],
        [['ClientBooking', 'inputValue', 'AdditionalServices', 'AdditionalServiceInputItem'],
          {namespace: namespace, form: 'qualified', singular: false }],
        [['ClientBooking', 'inputValue', 'AdditionalServices', 'AdditionalServiceInputItem', 'Code'],
          {namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'AdditionalServices', 'AdditionalServiceInputItem', 'Count'],
          {namespace: namespace, form: 'qualified', singular: true, type: 's:int' }],

        [['ClientBooking', 'inputValue', 'CustomerSalutationType'],          { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerName'],                    { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerFirstName'],               { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerPhone'],                   { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerFax'],                     { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerEmail'],                   { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerAddressStreet'],           { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerAddressAdditionalStreet'], { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerAddressZIP'],              { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerAddressPlace'],            { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerAddressState'],            { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CustomerAddressCountryCode'],      { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'Comment'],                         { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'Adults'],                          { namespace: namespace, form: 'qualified', singular: true, type: 's:int' }],
        [['ClientBooking', 'inputValue', 'Babies'],                          { namespace: namespace, form: 'qualified', singular: true, type: 's:int' }],
        [['ClientBooking', 'inputValue', 'Children'],                        { namespace: namespace, form: 'qualified', singular: true, type: 's:int' }],
        [['ClientBooking', 'inputValue', 'CheckIn'],                         { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CheckOut'],                        { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'LanguageCode'],                    { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CurrencyCode'],                    { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'RetailerCode'],                    { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'RetailerExtraCode'],               { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'PaymentType'],                     { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CreditCardType'],                  { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CreditCardNumber'],                { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CreditCardCvc'],                   { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CreditCardExpiry'],                { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'CreditCardHolder'],                { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'BankAccountNumber'],               { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'BankCode'],                        { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }],
        [['ClientBooking', 'inputValue', 'BankAccountHolder'],               { namespace: namespace, form: 'qualified', singular: true, type: 's:string' }]
      ])
    end

  end
end
