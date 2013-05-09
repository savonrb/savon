require 'spec_helper'

describe Wasabi do
  context 'with: telefonkatalogen.wsdl' do

    # reference: savon#295
    subject(:wsdl) { Wasabi.new fixture(:telefonkatalogen).read }

    it 'knows the operations' do
      operation = wsdl.operation(:sendsms)

      expect(operation.input).to eq('sendsms')
      expect(operation.soap_action).to eq('sendsms')
      expect(operation.nsid).to eq('tns')
    end

  end
end

