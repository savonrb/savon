require 'spec_helper'

describe Savon::Operation do

  it 'knows the #input_parts for authentication.xml' do
    operation = operation_for(
      fixture:   'wsdl/authentication',
      service:   'AuthenticationWebServiceImplService',
      port:      'AuthenticationWebServiceImplPort',
      operation: 'authenticate'
    )

    namespace = 'http://v1_0.ws.auth.order.example.com/'

    expect(operation.input_parts).to eq([
      [['authenticate'],             { namespace: namespace, form: 'qualified',   singular: true }],
      [['authenticate', 'user'],     { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['authenticate', 'password'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }]
    ])
  end

  it 'knows the #input_parts for amazon.xml' do
    operation = operation_for(
      fixture:   'wsdl/amazon',
      service:   'AmazonFPS',
      port:      'AmazonFPSPort',
      operation: 'Pay'
    )

    namespace = 'http://fps.amazonaws.com/doc/2008-09-17/'

    expect(operation.input_parts).to eq([
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

  it 'knows the #input_parts for awse.xml' do
    operation = operation_for(
      fixture:   'wsdl/awse',
      service:   'AWSECommerceService',
      port:      'AWSECommerceServicePort',
      operation: 'CartAdd'
    )

    namespace = 'http://webservices.amazon.com/AWSECommerceService/2011-08-01'

    expect(operation.input_parts).to eq([
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

  it 'knows the #input_parts for betfair.xml' do
    operation = operation_for(
      fixture:   'wsdl/betfair',
      service:   'BFExchangeService',
      port:      'BFExchangeService',
      operation: 'getBet'
    )

    ns1 = 'http://www.betfair.com/publicapi/v5/BFExchangeService/'
    ns2 = 'http://www.betfair.com/publicapi/types/exchange/v5/'

    expect(operation.input_parts).to eq([
      [['getBet'],                                      { namespace: ns1, form: 'qualified',   singular: true }],
      [['getBet', 'request'],                           { namespace: ns1, form: 'qualified',   singular: true }],
      [['getBet', 'request', 'header'],                 { namespace: ns2, form: 'unqualified', singular: true }],
      [['getBet', 'request', 'header', 'clientStamp'],  { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:long'   }],
      [['getBet', 'request', 'header', 'sessionToken'], { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['getBet', 'request', 'betId'],                  { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:long'   }],
      [['getBet', 'request', 'locale'],                 { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:string' }]
    ])
  end

  it 'knows the #input_parts for interhome.xml' do
    operation = operation_for(
      fixture:   'wsdl/interhome',
      service:   'WebService',
      port:      'WebServiceSoap',
      operation: 'ClientBooking'
    )

    namespace = 'http://www.interhome.com/webservice'

    expect(operation.input_parts).to eq([
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

  it 'knows the #input_parts for jira.xml' do
    operation = operation_for(
      fixture:   'wsdl/jira',
      service:   'JiraSoapServiceService',
      port:      'jirasoapservice-v2',
      operation: 'updateGroup'
    )

    namespace = 'http://beans.soap.rpc.jira.atlassian.com'

    # TODO: check if jira is rpc/encoded. at least soapUI adds type-attributes to these elements.
    expect(operation.input_parts).to eq([
      [['in0'],          { namespace: nil,       form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['in1'],          { namespace: nil,       form: 'unqualified', singular: true }],
      [['in1', 'name'],  { namespace: namespace, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['in1', 'users'], { namespace: namespace, form: 'unqualified', singular: true }]
    ])
  end

  it 'knows the #input_parts for taxcloud.xml' do
    operation = operation_for(
      fixture:   'wsdl/taxcloud',
      service:   'TaxCloud',
      port:      'TaxCloudSoap',
      operation: 'VerifyAddress'
    )

    namespace = 'http://taxcloud.net'

    expect(operation.input_parts).to eq([
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

  it 'knows the #input_parts for team_software.xml' do
    operation = operation_for(
      fixture:   'wsdl/team_software',
      service:   'ServiceManager',
      port:      'BasicHttpBinding_IWinTeamServiceManager',
      operation: 'Login'
    )

    namespace = 'http://tempuri.org/'

    expect(operation.input_parts).to eq([
      [['Login'],               { namespace: namespace, form: 'qualified', singular: true }],
      [['Login', 'MappingKey'], { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string' }]
    ])
  end

  it 'knows the #input_parts for telefonkatalogen.xml' do
    operation = operation_for(
      fixture:   'wsdl/telefonkatalogen',
      service:   'SendSms',
      port:      'SendSmsPort',
      operation: 'sendsms'
    )

    expect(operation.input_parts).to eq([
      [['sender'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['cellular'],    { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['msg'],         { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['smsnumgroup'], { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['emailaddr'],   { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['udh'],         { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['datetime'],    { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['format'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }],
      [['dlrurl'],      { namespace: nil, form: 'unqualified', singular: true, type: 'xsd:string' }]
    ])
  end

  it 'knows the #input_parts for wasmuth.xml' do
    operation = operation_for(
      fixture:   'wsdl/wasmuth',
      service:   'OnlineSyncService',
      port:      'OnlineSyncPort',
      operation: 'getStTables'
    )

    namespace = 'http://ws.online.msw/'

    expect(operation.input_parts).to eq([
      [['getStTables'],             { namespace: namespace, form: 'qualified',   singular: true }],
      [['getStTables', 'username'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['getStTables', 'password'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
      [['getStTables', 'version'],  { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }]
    ])
  end

  def operation_for(options)
    fixture   = options.fetch(:fixture)
    service   = options.fetch(:service)
    port      = options.fetch(:port)
    operation = options.fetch(:operation)

    client = Savon.new fixture(fixture)
    client.operation(service, port, operation)
  end

end
