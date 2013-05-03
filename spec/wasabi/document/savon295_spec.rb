require 'spec_helper'

describe Wasabi::Document do
  context 'with: savon295.wsdl' do

    subject(:document) { Wasabi::Document.new fixture(:savon295).read }

    it 'knows the sendsms operation' do
      operation = document.operations[:sendsms]

      expect(operation.soap_action).to eq('sendsms')
      expect(operation.input).to eq('sendsms')
      expect(operation.nsid).to eq('tns')
    end

  end
end
