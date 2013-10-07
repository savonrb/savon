require 'spec_helper'

describe 'Integration with Equifax' do

  subject(:client) { Savon.new fixture('wsdl/equifax') }

  let(:service_name) { :canadav2 }
  let(:port_name)    { :canadaHttpPortV2 }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'canadav2' => {
        ports: {
          'canadaHttpPortV2' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'https://pilot.eidverifier.com/uru/soap/cert/canadav2'
          }
        }
      }
    )
  end

  it 'knows operations with attributes and attribute groups' do
    operation = client.operation(service_name, port_name, 'startTransaction')

    expect(operation.soap_action).to eq('')
    expect(operation.endpoint).to eq('https://pilot.eidverifier.com/uru/soap/cert/canadav2')

    ns1 = 'http://eid.equifax.com/soap/schema/canada/v2'

    expect(operation.body_parts).to eq([
      [['InitialRequest'],                                                          { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'Identity'],                                              { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'Identity', 'Name'],                                      { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'Identity', 'Name', 'FirstName'],                         { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'Name', 'MiddleName'],                        { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'Name', 'MiddleInitial'],                     { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'Name', 'LastName'],                          { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'Name', 'Suffix'],                            { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],

      [['InitialRequest', 'Identity', 'Address'],                                   { namespace: ns1, form: 'qualified', singular: false,
                                                                                      attributes: {
                                                                                        'timeAtAddress' => { optional: true },
                                                                                        'addressType'   => { optional: false }
                                                                                      }
                                                                                    }],

      [['InitialRequest', 'Identity', 'Address', 'FreeFormAddress'],                { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'Identity', 'Address', 'FreeFormAddress', 'AddressLine'], { namespace: ns1, form: 'qualified', singular: false,  type: 'string' }],
      [['InitialRequest', 'Identity', 'Address', 'HybridAddress'],                  { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'Identity', 'Address', 'HybridAddress', 'AddressLine'],   { namespace: ns1, form: 'qualified', singular: false, type: 'string' }],
      [['InitialRequest', 'Identity', 'Address', 'HybridAddress', 'City'],          { namespace: ns1, form: 'qualified', singular: true,  type: 'string' }],
      [['InitialRequest', 'Identity', 'Address', 'HybridAddress', 'Province'],      { namespace: ns1, form: 'qualified', singular: true,  type: 'string' }],
      [['InitialRequest', 'Identity', 'Address', 'HybridAddress', 'PostalCode'],    { namespace: ns1, form: 'qualified', singular: true,  type: 'string' }],
      [['InitialRequest', 'Identity', 'SIN'],                                       { namespace: ns1, form: 'qualified', singular: true,  type: 'string' }],
      [['InitialRequest', 'Identity', 'DateOfBirth'],                               { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'Identity', 'DateOfBirth', 'Day'],                        { namespace: ns1, form: 'qualified', singular: true,  type: 'positiveInteger' }],
      [['InitialRequest', 'Identity', 'DateOfBirth', 'Month'],                      { namespace: ns1, form: 'qualified', singular: true,  type: 'positiveInteger' }],
      [['InitialRequest', 'Identity', 'DateOfBirth', 'Year'],                       { namespace: ns1, form: 'qualified', singular: true,  type: 'positiveInteger' }],

      [['InitialRequest', 'Identity', 'DriversLicense'],                            { namespace: ns1, form: 'qualified', singular: true,
                                                                                      attributes: {
                                                                                        'driversLicenseAddressType'=> { optional: true }
                                                                                      }
                                                                                    }],

      [['InitialRequest', 'Identity', 'DriversLicense', 'Number'],                  { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'DriversLicense', 'Province'],                { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],

      [['InitialRequest', 'Identity', 'PhoneNumber'],                               { namespace: ns1, form: 'qualified', singular: false,
                                                                                      attributes: {
                                                                                        'phoneType' => { optional: true }
                                                                                      }
                                                                                    }],

      [['InitialRequest', 'Identity', 'PhoneNumber', 'AreaCode'],                   { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'PhoneNumber', 'Exchange'],                   { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'PhoneNumber', 'Number'],                     { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'PhoneNumber', 'PhoneNumber'],                { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'Email'],                                     { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'IPAddress'],                                 { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'CreditCardNumber'],                          { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'Identity', 'CustomerId'],                                { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'ProcessingOptions'],                                     { namespace: ns1, form: 'qualified', singular: true }],
      [['InitialRequest', 'ProcessingOptions', 'Language'],                         { namespace: ns1, form: 'qualified', singular: true, type: 'string' }],
      [['InitialRequest', 'ProcessingOptions', 'EnvironmentOverride'],              { namespace: ns1, form: 'qualified', singular: true, type: 'string' }]
    ])
  end

  it 'creates an example body with attributes' do
    operation = client.operation(service_name, port_name, :startTransaction)

    expect(operation.example_body).to eq(
      InitialRequest: {
        Identity: {
          Name: {
            FirstName: 'string',
            MiddleName: 'string',
            MiddleInitial: 'string',
            LastName: 'string',
            Suffix: 'string'
          },
          Address: [
            {
              FreeFormAddress: {
                AddressLine: ['string']
              },
              HybridAddress: {
                AddressLine: ['string'],
                City: 'string',
                Province: 'string',
                PostalCode: 'string'
              },

              # attributes are prefixed with an underscore.
              _timeAtAddress: 'nonNegativeInteger',
              _addressType: 'string'
            }
          ],
          SIN: 'string',
          DateOfBirth: {
            Day: 'positiveInteger',
            Month: 'positiveInteger',
            Year: 'positiveInteger'
          },
          DriversLicense: {
            Number: 'string',
            Province: 'string',

            # another attribute
            _driversLicenseAddressType: 'string'
          },
          PhoneNumber: [
            {
              AreaCode: 'string',
              Exchange: 'string',
              Number: 'string',
              PhoneNumber: 'string',

              # another attribute
              _phoneType: 'string'
            }
          ],
          Email: 'string',
          IPAddress: 'string',
          CreditCardNumber: 'string',
          CustomerId: 'string'
        },
        ProcessingOptions: {
          Language: 'string',
          EnvironmentOverride: 'string'
        }
      }
    )
  end

  it 'creates a request with attributes' do
    operation = client.operation(service_name, port_name, :startTransaction)

    operation.body = {
      InitialRequest: {
        Identity: {
          Address: [
            {
              FreeFormAddress: {
                AddressLine: ['The original', 'Abbey Road, London']
              },
              HybridAddress: {
                AddressLine: ['The original', 'Abbey Road'],
                City: 'London',
                Province: 'Camden',
                PostalCode: 'NW8 9BS'
              },

              # attributes are prefixed with an underscore
              _timeAtAddress: 3,
              _addressType: 'public'
            }
          ]
        }
      }
    }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://eid.equifax.com/soap/schema/canada/v2"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header>
        </env:Header>
        <env:Body>
          <lol0:InitialRequest>
            <lol0:Identity>
              <lol0:Address timeAtAddress="3" addressType="public">
                <lol0:FreeFormAddress>
                  <lol0:AddressLine>The original</lol0:AddressLine>
                  <lol0:AddressLine>Abbey Road, London</lol0:AddressLine>
                </lol0:FreeFormAddress>
                <lol0:HybridAddress>
                  <lol0:AddressLine>The original</lol0:AddressLine>
                  <lol0:AddressLine>Abbey Road</lol0:AddressLine>
                  <lol0:City>London</lol0:City>
                  <lol0:Province>Camden</lol0:Province>
                  <lol0:PostalCode>NW8 9BS</lol0:PostalCode>
                </lol0:HybridAddress>
              </lol0:Address>
            </lol0:Identity>
          </lol0:InitialRequest>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
