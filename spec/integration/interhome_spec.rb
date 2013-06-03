require 'spec_helper'

describe 'Integration with Interhome' do

  subject(:client) { Savon.new fixture('wsdl/interhome') }

  let(:service_name) { :WebService }
  let(:port_name)    { :WebServiceSoap }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
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
    operation = client.operation(service_name, port_name, 'ClientBooking')

    expect(operation.soap_action).to eq('http://www.interhome.com/webservice/ClientBooking')
    expect(operation.endpoint).to eq('https://webservices.interhome.com/quality/partnerV3/WebService.asmx')

    namespace = 'http://www.interhome.com/webservice'

    expect(operation.body_parts).to eq([
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

  # implicit headers. reference: http://www.ibm.com/developerworks/library/ws-tip-headers/index.html
  it 'creates an example header' do
    operation = client.operation(service_name, port_name, :Availability)

    expect(operation.example_header).to eq(
      ServiceAuthHeader: {
        Username: 'string',
        Password: 'string'
      }
    )
  end

  it 'creates an example body including optional elements' do
    operation = client.operation(service_name, port_name, :Availability)

    expect(operation.example_body).to eq(
      Availability: {

        # These are optional.
        inputValue: {
          AccommodationCode: 'string',
          CheckIn: 'string',
          CheckOut: 'string'
        }

      }
    )
  end

  it 'skips optional elements in the request' do
    operation = client.operation(service_name, port_name, :Availability)

    operation.header = {
      ServiceAuthHeader: {
        Username: 'test',
        Password: 'secret'
      }
    }

    operation.body = {
      Availability: {
        inputValue: {
          # Leaving out two optional elements on purpose.
          AccommodationCode: 'secret'
        }
      }
    }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://www.interhome.com/webservice"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header>
          <lol0:ServiceAuthHeader>
            <lol0:Username>test</lol0:Username>
            <lol0:Password>secret</lol0:Password>
          </lol0:ServiceAuthHeader>
        </env:Header>
        <env:Body>
          <lol0:Availability>
            <lol0:inputValue>
              <lol0:AccommodationCode>secret</lol0:AccommodationCode>
            </lol0:inputValue>
          </lol0:Availability>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
