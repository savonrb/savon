require 'spec_helper'

describe Wasabi do
  context 'with: namespaced_actions.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:namespaced_actions).read }

    it 'knows the target namespace' do
      expect(wsdl.target_namespace).to eq('http://api.example.com/api/')
    end

    it 'knows the namespaces' do
      expect(wsdl.namespaces).to eq(
        'http'    => 'http://schemas.xmlsoap.org/wsdl/http/',
        'wsdl'    => 'http://schemas.xmlsoap.org/wsdl/',
        'soap'    => 'http://schemas.xmlsoap.org/wsdl/soap/',
        'soap12'  => 'http://schemas.xmlsoap.org/wsdl/soap12/',
        's'       => 'http://www.w3.org/2001/XMLSchema',
        'tm'      => 'http://microsoft.com/wsdl/mime/textMatching/',
        'soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
        'mime'    => 'http://schemas.xmlsoap.org/wsdl/mime/',
        'tns'     => 'http://api.example.com/api/'
      )
    end

    it 'knows the endpoint' do
      expect(wsdl.endpoint).to eq(URI.parse 'https://api.example.com/api/api.asmx')
    end

    it 'works fine with dot-namespaced operations' do
      operation = wsdl.operation('DeleteClient')

      expect(operation.input).to eq('Client.Delete')
      expect(operation.soap_action).to eq('http://api.example.com/api/Client.Delete')
      expect(operation.nsid).to eq('tns')
    end

  end
end
