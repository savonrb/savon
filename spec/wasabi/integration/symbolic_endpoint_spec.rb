require 'spec_helper'

describe Wasabi do
  context 'with: symbolic_endpoint.wsdl' do

    subject(:wsdl) { Wasabi.new(xml) }

    let(:xml) { fixture(:symbolic_endpoint).read }

    it 'allows symbolic endpoints' do
      operation = wsdl.operation('ptsLiesListe')
      expect(operation.endpoint).to eq('http://server:port/CICS/CWBA/DFHWSDSH/DQ5006')
    end

  end
end
