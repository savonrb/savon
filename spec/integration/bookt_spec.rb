require 'spec_helper'

describe 'Integration with Bookt' do

  subject(:client) { Savon.new(wsdl_url, http_mock) }

  let(:wsdl_url)  { 'http://connect.bookt.com/svc/connect.svc?wsdl' }
  let(:wsdl2_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl1' }
  let(:wsdl3_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl0' }

  before do
    http_mock.fake_request(wsdl_url,  'wsdl/bookt/bookt.wsdl')
    http_mock.fake_request(wsdl2_url, 'wsdl/bookt/bookt2.wsdl')
    http_mock.fake_request(wsdl3_url, 'wsdl/bookt/bookt3.wsdl')

    # 16 schemas to import
    schema_import_base = 'http://connect.bookt.com/svc/connect.svc?xsd=xsd%d'
    (0..15).each do |i|
      url = schema_import_base % i
      http_mock.fake_request(url, "wsdl/bookt/bookt#{i}.xsd")
    end
  end

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'Connect'       => {
        :ports        => {
          'IConnect'  => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'http://connect.bookt.com/svc/connect.svc'
          }
        }
      }
    )
  end

  it 'resolves WSDL imports to get the operations' do
    operations = client.operations('Connect', 'IConnect')
    expect(operations.count).to eq(26)
  end

  it 'resolves XML Schema imports to get all elements' do
    get_booking = client.operation('Connect', 'IConnect', 'GetBooking')

    namespace = 'https://connect.bookt.com/connect'

    expect(get_booking.input_parts).to eq([
      [['GetBooking'],                  { namespace: namespace, form: 'qualified', singular: true }],
      [['GetBooking', 'apiKey'],        { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string'  }],
      [['GetBooking', 'bookingID'],     { namespace: namespace, form: 'qualified', singular: true, type: 'xs:string'  }],
      [['GetBooking', 'useInternalID'], { namespace: namespace, form: 'qualified', singular: true, type: 'xs:boolean' }]
    ])
  end

end
