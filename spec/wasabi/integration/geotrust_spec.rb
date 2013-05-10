require 'spec_helper'

describe Wasabi do
  context 'with: geotrust.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:geotrust).read }

    it 'knows the target namespace' do
      expect(wsdl.target_namespace).to eq('http://api.geotrust.com/webtrust/query')
    end

    it 'knows the endpoint' do
      expect(wsdl.endpoint).to eq(URI.parse 'https://test-api.geotrust.com:443/webtrust/query.jws')
    end

    it 'knows the operations' do
      operation = wsdl.operation('GetQuickApproverList')

      expect(operation.input).to eq('GetQuickApproverList')
      expect(operation.soap_action).to eq('GetQuickApproverList')
      expect(operation.nsid).to eq(nil)

      operation = wsdl.operation('hello')

      expect(operation.input).to eq('hello')
      expect(operation.soap_action).to eq('hello')
      expect(operation.nsid).to eq(nil)
    end

  end
end
