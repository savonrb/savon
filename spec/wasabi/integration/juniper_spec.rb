require "spec_helper"

describe Wasabi do
  context 'with: juniper.wsdl' do

    subject(:wsdl) { Wasabi.new(xml) }

    let(:xml) { fixture(:juniper).read }

    it 'does not blow up when an extension base element is defined in an import' do
      operation = wsdl.documents.operations[:get_system_info_request]

      operation.input.should == 'GetSystemInfoRequest'
      operation.soap_action.should == 'urn:#GetSystemInfoRequest'
      operation.nsid.should == 'impl'
    end

  end
end
