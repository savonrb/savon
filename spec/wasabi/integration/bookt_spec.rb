require 'spec_helper'

describe Wasabi do
  context 'with: bookt.wsdl' do

    subject(:wsdl)  { Wasabi.new(wsdl_url, http_mock) }

    let(:wsdl_url)  { 'http://connect.bookt.com/svc/connect.svc?wsdl' }
    let(:wsdl2_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl1' }
    let(:wsdl3_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl0' }

    before do
      http_mock.fake_request(wsdl_url,  'bookt/bookt.wsdl')
      http_mock.fake_request(wsdl2_url, 'bookt/bookt2.wsdl')
      http_mock.fake_request(wsdl3_url, 'bookt/bookt3.wsdl')

      # 16 schemas to import
      schema_import_base = 'http://connect.bookt.com/svc/connect.svc?xsd=xsd%d'
      (0..15).each do |i|
        url = schema_import_base % i
        http_mock.fake_request(url, "bookt/bookt#{i}.xsd")
      end
    end

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
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
      operations = wsdl.operations('Connect', 'IConnect')
      expect(operations.count).to eq(26)
    end

    it 'resolves XML Schema imports to get all elements' do
      get_booking = wsdl.operation('Connect', 'IConnect', 'GetBooking')

      input = get_booking.input
      expect(input.count).to eq(1)

      namespace = 'https://connect.bookt.com/connect'

      expect(input.first.to_a).to eq([
        [['GetBooking'],                  { namespace: namespace, form: 'qualified' }],
        [['GetBooking', 'apiKey'],        { namespace: namespace, form: 'qualified', type: 'xs:string'  }],
        [['GetBooking', 'bookingID'],     { namespace: namespace, form: 'qualified', type: 'xs:string'  }],
        [['GetBooking', 'useInternalID'], { namespace: namespace, form: 'qualified', type: 'xs:boolean' }]
      ])
    end

  end
end

