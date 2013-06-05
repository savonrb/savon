require 'spec_helper'

describe 'Integration with Rio II' do

  subject(:client) { Savon.new(wsdl_url) }

  let(:wsdl_url) { 'http://193.155.1.72/MyCentral-RioII-Services/SecurityService.svc?wsdl' }
  let(:wsdl0_url) { 'http://193.155.1.72/MyCentral-RioII-Services/SecurityService.svc?wsdl=wsdl0' }

  before do
    http_mock.fake_request(wsdl_url,  'wsdl/rio2/rio2.wsdl')
    http_mock.fake_request(wsdl0_url, 'wsdl/rio2/rio2_0.wsdl')

    # 4 schemas to import
    schema_import_base = 'http://193.155.1.72/MyCentral-RioII-Services/SecurityService.svc?xsd=xsd%d'
    (0..3).each do |i|
      url = schema_import_base % i
      http_mock.fake_request(url, "wsdl/rio2/rio2_#{i}.xsd")
    end
  end

  it 'only downloads WSDL and XML Schema imports once per location' do
    expect(client.services).to eq(
      'SecurityService' => {
        ports: {
          'BasicHttpBinding_ISecurityService' => {
            type: 'http://schemas.xmlsoap.org/wsdl/soap/',
            location: 'http://193.155.1.72/MyCentral-RioII-Services/SecurityService.svc/soap'
          }
        }
      }
    )
  end

  it 'knows the GetSessionState operation' do
    service, port = :SecurityService, :BasicHttpBinding_ISecurityService
    operation = client.operation(service, port, :GetSessionState)

    expect(operation.input_style).to eq('document/literal')

    expect(operation.example_body).to eq(
      GetSessionState: {
        session: {
          ApplicationId: 'string',
          CultureCode: 'string',
          SessionId: 'string'
        },
        request: {
          Context: 'string'
        }
      }
    )
  end

end
