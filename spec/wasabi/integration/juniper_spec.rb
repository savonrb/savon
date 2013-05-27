require "spec_helper"

describe Wasabi do
  context 'with: juniper.wsdl' do

    subject(:wsdl) { Wasabi.new(xml) }

    let(:xml) { fixture('juniper.wsdl').read }

    it 'returns a map of services and ports' do
      pending 'fails because the schema can not be resolved'
      #expect(wsdl.services).to eq(
        #'SystemService' => {
          #:ports => {
            #'System'   => {
              #:type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              #:location => 'https://10.1.1.1:8443/axis2/services/SystemService'
            #}
          #}
        #}
      #)
    end

    it 'does not blow up when an extension base element is defined in an import' do

      pending 'this one is waiting for support for xml schema imports!'

#     operation = wsdl.operation('SystemService', 'System', 'GetSystemInfoRequest')

#     operation.soap_action.should == 'urn:#GetSystemInfoRequest'

#     expect(operation.input.count).to eq(1)

#     expect(operation.input.first.to_a).to eq([
#       [['authenticate'],             { namespace: 'http://v1_0.ws.auth.order.example.com/' }],
#       [['authenticate', 'user'],     { namespace: nil, type: 'xs:string' }],
#       [['authenticate', 'password'], { namespace: nil, type: 'xs:string' }]
#     ])
#     expect(input.nsid).to eq('impl')
#     expect(input.local).to eq('GetSystemInfoRequest')
    end

  end
end
