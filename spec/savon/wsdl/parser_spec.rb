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
