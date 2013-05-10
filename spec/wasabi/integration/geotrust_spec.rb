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
      pending "this fixture is missing a message element! " \
              "find out if we need to handle this case or if the fixture is incomplete." do

        operation = wsdl.operation('GetQuickApproverList')
        expect(operation.name).to eq('THIS-TEST-FAILS')

      end
    end

  end
end
