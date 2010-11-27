require "spec_helper"

describe Savon::WSDL::Parser do

  context "with namespaced_actions.xml" do
    let(:parser) { new_parser :namespaced_actions }

    it "should know the target namespace" do
      parser.namespace.should == "http://api.example.com/api/"
    end

    it "should know the SOAP endpoint" do
      parser.endpoint.should == URI("https://api.example.com/api/api.asmx")
    end

    it "should know the available SOAP operations" do
      parser.operations.should match_operations(
        :get_api_key => { :input => "GetApiKey", :action => "http://api.example.com/api/User.GetApiKey" },
        :delete_client => { :input => "DeleteClient", :action => "http://api.example.com/api/Client.Delete" },
        :get_clients => { :input => "GetClients", :action => "http://api.example.com/api/User.GetClients" }
      )
    end
  end

  context "with no_namespace.xml" do
    let(:parser) { new_parser :no_namespace }

    it "should know the target namespace" do
      parser.namespace.should == "urn:ActionWebService"
    end

    it "should know the SOAP endpoint" do
      parser.endpoint.should == URI("http://example.com/api/api")
    end

    it "should know the available SOAP operations" do
      parser.operations.should match_operations(
        :search_user => { :input => "SearchUser", :action => "/api/api/SearchUser" },
        :get_user_login_by_id => { :input => "GetUserLoginById", :action => "/api/api/GetUserLoginById" },
        :get_all_contacts => { :input => "GetAllContacts", :action => "/api/api/GetAllContacts" }
      )
    end
  end

  context "with geotrust.xml" do
    let(:parser) { new_parser :geotrust }

    it "should know the target namespace" do
      parser.namespace.should == "http://api.geotrust.com/webtrust/query"
    end

    it "should know the SOAP endpoint" do
      parser.endpoint.should == URI("https://test-api.geotrust.com/webtrust/query.jws")
    end

    it "should know the available SOAP operations" do
      parser.operations.should match_operations(
        :get_quick_approver_list => { :input => "GetQuickApproverList", :action => "GetQuickApproverList" },
        :hello => { :input => "hello", :action => "hello" }
      )
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
    parser = Savon::WSDL::Parser.new
    REXML::Document.parse_stream Fixture[:wsdl, fixture], parser
    parser
  end

end
