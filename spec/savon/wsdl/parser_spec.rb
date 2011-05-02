require "spec_helper"

describe Savon::WSDL::Parser do

  context "with namespaced_actions.xml" do
    let(:parser) { new_parser :namespaced_actions }

    it "should return the target namespace" do
      parser.namespace.should == "http://api.example.com/api/"
    end

    it "should return the SOAP endpoint" do
      parser.endpoint.should == URI("https://api.example.com/api/api.asmx")
    end

    it "should return the available SOAP operations" do
      parser.operations.should match_operations(
        :get_api_key => { :input => "GetApiKey", :action => "http://api.example.com/api/User.GetApiKey" },
        :delete_client => { :input => "DeleteClient", :action => "http://api.example.com/api/Client.Delete" },
        :get_clients => { :input => "GetClients", :action => "http://api.example.com/api/User.GetClients" }
      )
    end

    it "should return that :element_form_default is set to :qualified" do
      parser.element_form_default.should == :qualified
    end
  end

  context "with no_namespace.xml" do
    let(:parser) { new_parser :no_namespace }

    it "should return the target namespace" do
      parser.namespace.should == "urn:ActionWebService"
    end

    it "should return the SOAP endpoint" do
      parser.endpoint.should == URI("http://example.com/api/api")
    end

    it "should return the available SOAP operations" do
      parser.operations.should match_operations(
        :search_user => { :input => "SearchUser", :action => "/api/api/SearchUser" },
        :get_user_login_by_id => { :input => "GetUserLoginById", :action => "/api/api/GetUserLoginById" },
        :get_all_contacts => { :input => "GetAllContacts", :action => "/api/api/GetAllContacts" }
      )
    end

    it "should return that :element_form_default is set to :unqualified" do
      parser.element_form_default.should == :unqualified
    end

    it "can list the types" do
      parser.types.keys.sort.should ==
        ["McContact", "McContactArray", "MpUser", "MpUserArray"]
    end

    it "ignores xsd:all" do
      parser.types["MpUser"].keys.should == [:namespace]
    end

  end

  context "with geotrust.xml" do
    let(:parser) { new_parser :geotrust }

    it "should return the target namespace" do
      parser.namespace.should == "http://api.geotrust.com/webtrust/query"
    end

    it "should return the SOAP endpoint" do
      parser.endpoint.should == URI("https://test-api.geotrust.com/webtrust/query.jws")
    end

    it "should return the available SOAP operations" do
      parser.operations.should match_operations(
        :get_quick_approver_list => { :input => "GetQuickApproverList", :action => "GetQuickApproverList" },
        :hello => { :input => "hello", :action => "hello" }
      )
    end

    it "should return that :element_form_default is set to :qualified" do
      parser.element_form_default.should == :qualified
    end
  end

  context "with two_bindings.xml" do
    let(:parser) { new_parser :two_bindings }

    it "should merge operations from all binding sections (until we have an example where it makes sense to do otherwise)" do
      parser.operations.keys.map(&:to_s).sort.should ==
        %w{post post11only post12only}
    end
  end

  context "with multiple_namespaces.xml" do
    let(:parser) { new_parser :multiple_namespaces }

    it "can list the messages" do
      pending("we don't need this yet, so not implemented")
      parser.messages.keys.sort.should == ["SaveSoapIn", "SaveSoapOut"]
    end

    it "can go from message to element" do
      pending("we don't need this yet, so not implemented")
      parser.messages["SaveSoapIn"].should == "Save"
    end

    it "have an entry in input_message for everything listed" do
      pending("we don't need this yet, so not implemented")
      parser.input_message.keys.should == ["Save"]
    end

    it "can go from an action to a message" do
      pending("we don't need this yet, so not implemented")
      parser.input_message["Save"].should == "SaveSoapIn"
    end

    it "can list the types" do
      parser.types.keys.sort.should == ["Article", "Save"]
    end

    it "records the namespace for each type" do
      parser.types["Save"][:namespace].should == "http://example.com/actions"
    end

    it "records the fields under a type" do
      parser.types["Save"].keys.should =~ ["article", :namespace]
    end

    it "records multiple fields when there are more than one" do
      parser.types["Article"].keys.should =~ ["Title", "Author", :namespace]
    end

    it "records the type of a field" do
      parser.types["Save"]["article"][:type].should == "article:Article"
      parser.namespaces["article"].should == "http://example.com/article"
    end

  end

  context "if the WSDL defines xs:schema without targetNamespace" do
    # Don't know if real WSDL files omit targetNamespace from xs:schema,
    # but I suppose we should do something reasonable if they do.

    it "defaults to the target namespace from xs:definitions" do
      wsdl = %Q{
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
      parser = Savon::WSDL::Parser.new(Nokogiri::XML(wsdl))
      parser.parse

      parser.types["Save"][:namespace].should == "http://def.example.com"
    end
  end

  context "with soap12.xml" do
    let(:parser) { new_parser :soap12 }

    it "should return the endpoint" do
      parser.endpoint.should == URI("http://blogsite.example.com/endpoint12")
    end
  end

  RSpec::Matchers.define :match_operations do |expected|
    match do |actual|
      actual.should have(expected.keys.size).items
      actual.keys.should include(*expected.keys)
      actual.each { |key, value| value.should == expected[key] }
    end
  end

  def new_parser(fixture)
    parser = Savon::WSDL::Parser.new(Nokogiri::XML(Fixture[:wsdl, fixture]))
    parser.parse
    parser
  end

end
