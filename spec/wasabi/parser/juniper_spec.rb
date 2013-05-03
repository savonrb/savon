require "spec_helper"

describe Wasabi::Parser do
  context 'with: juniper.wsdl' do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) { fixture(:juniper).read }

    it 'does not blow up when an extension base element is defined in an import' do
      operation = subject.operations[:get_system_info_request]

      operation.input.should == 'GetSystemInfoRequest'
      operation.soap_action.should == 'urn:#GetSystemInfoRequest'
      operation.nsid.should == 'impl'
    end

  end
end
