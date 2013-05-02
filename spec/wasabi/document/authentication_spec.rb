require "spec_helper"

describe Wasabi::Document do
  context "with: authentication.wsdl" do

    subject(:document) { Wasabi::Document.new fixture(:authentication).read }

    its(:namespace) { should == "http://v1_0.ws.auth.order.example.com/" }

    it 'knows all the namespaces' do
      expect(document.namespaces).to eq(
        'tns'  => 'http://v1_0.ws.auth.order.example.com/',
        'xs'   => 'http://www.w3.org/2001/XMLSchema',
        'ns1'  => 'http://cxf.apache.org/bindings/xformat',
        'soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
        'wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
        'xsd'  => 'http://www.w3.org/2001/XMLSchema'
      )
    end

    its(:endpoint) { should == URI("http://example.com/validation/1.0/AuthenticationService") }

    its(:element_form_default) { should == :unqualified }

    it { should have(1).operations }

    its(:operations) do
      should == {
        :authenticate => { :input => "authenticate", :action => "authenticate", :namespace_identifier => "tns" }
      }
    end

  end
end
