require 'spec_helper'

describe Wasabi do
  context 'with: bookt.wsdl' do

    subject(:wsdl)  { Wasabi.new(wsdl_url) }

    let(:wsdl_url)  { 'http://connect.bookt.com/svc/connect.svc?wsdl' }
    let(:wsdl2_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl1' }
    let(:wsdl3_url) { 'http://connect.bookt.com/svc/connect.svc?wsdl=wsdl0' }

    before do
      mock_request wsdl_url,  :bookt
      mock_request wsdl2_url, :bookt2
      mock_request wsdl3_url, :bookt3
    end

    it 'resolves WSDL imports to get the operations' do
      expect(wsdl.documents.operations).to_not be_empty
    end

  end
end

