require 'spec_helper'

describe Wasabi do
  context 'with: geotrust.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:geotrust).read }

    it 'knows the target namespace' do
      expect(wsdl.target_namespace).to eq('http://api.geotrust.com/webtrust/query')
    end

    it 'adds namespace declarations from elements to the global collection' do
      element = wsdl.schemas.element('GetQuickApproverList')

      expect(wsdl.namespaces).to_not include(
        'quer' => 'http://api.geotrust.com/webtrust/query'
      )

      # only adds the namespaces to the global collection when you actually
      # trigger parsing an element's child elements. this might be good enough
      # for gathering the namespaces for an operation if the know all the elements,
      # but it's also a little weird.
      element.children

      expect(wsdl.namespaces).to include(
        'quer' => 'http://api.geotrust.com/webtrust/query'
      )
    end

    it 'finds namespace declarations on the actual elements' do
      element = wsdl.schemas.element('GetQuickApproverList')
      expect(element.children).to eq([
        {
          :name        => 'Request',
          :type        => 'quer:GetQuickApproverListInput',
          :simple_type => false,
          :form        => nil,
          :singular    => true
        }
      ])
    end

    it 'knows the operations' do
      pending "this fixture is missing a message element! " \
              "find out if we need to handle this case or if the fixture is incomplete." do

        operation = wsdl.operation('GetQuickApproverList')
        expect(operation.name).to eq('THIS-TEST-FAILS')
        expect(operation.endpoint).to eq('https://test-api.geotrust.com:443/webtrust/query.jws')
      end
    end

  end
end
