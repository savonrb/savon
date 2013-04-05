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
      request = subject.operations[:get_system_info_request]

      request[:input].should == 'GetSystemInfoRequest'
      request[:action].should == 'urn:#GetSystemInfoRequest'
      request[:namespace_identifier].should == 'impl'
    end

  end
end
