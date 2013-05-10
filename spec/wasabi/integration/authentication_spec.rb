require 'spec_helper'

describe Wasabi do
  context 'with: authentication.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:authentication).read }

    it 'knows the target namespace' do
      expect(wsdl.target_namespace).to eq('http://v1_0.ws.auth.order.example.com/')
    end

    it 'knows the namespaces' do
      expect(wsdl.namespaces).to eq(
        'tns'  => 'http://v1_0.ws.auth.order.example.com/',
        'xs'   => 'http://www.w3.org/2001/XMLSchema',
        'ns1'  => 'http://cxf.apache.org/bindings/xformat',
        'soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
        'wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
        'xsd'  => 'http://www.w3.org/2001/XMLSchema'
      )
    end

    it 'knows the operations' do
      operation = wsdl.operation('authenticate')

      expect(operation.input).to eq('authenticate')
      expect(operation.soap_action).to eq('')
      expect(operation.nsid).to eq('tns')
      expect(operation.endpoint).to eq('http://example.com/validation/1.0/AuthenticationService')
    end

  end
end

