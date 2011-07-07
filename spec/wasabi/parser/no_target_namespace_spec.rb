require "spec_helper"

describe Wasabi::Parser do
  context "with a WSDL defining xs:schema without targetNamespace" do

    subject do
      parser = Wasabi::Parser.new Nokogiri::XML(xml)
      parser.parse
      parser
    end

    let(:xml) do
      %Q{
        <definitions xmlns='http://schemas.xmlsoap.org/wsdl/'
          xmlns:xs='http://www.w3.org/2001/XMLSchema'
          targetNamespace='http://def.example.com'>
          <types>
            <xs:schema elementFormDefault='qualified'>
              <xs:element name='Save'>
                <xs:complexType></xs:complexType>
              </xs:element>
            </xs:schema>
          </types>
        </definitions>
      }
    end

    # Don't know if real WSDL files omit targetNamespace from xs:schema,
    # but I suppose we should do something reasonable if they do.

    it "defaults to the target namespace from xs:definitions" do
      subject.types["Save"][:namespace].should == "http://def.example.com"
    end

  end
end
