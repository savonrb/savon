require "spec_helper"

describe Hash do

  describe "find_soap_body" do
    it "should return the content from the 'soap:Body' element" do
      soap_body = { "soap:Envelope" => { "soap:Body" => "content" } }
      soap_body.find_soap_body.should == "content"
    end

    it "should return an empty Hash in case the 'soap:Body' element could not be found" do
      soap_body = { "some_hash" => "content" }
      soap_body.find_soap_body.should == {}
    end
  end

  describe "map_soap_response" do
    it "should convert Hash key Strings to snake_case Symbols" do
      soap_response = { "userResponse" => { "accountStatus" => "active" } }
      result = { :user_response => { :account_status => "active" } }

      soap_response.map_soap_response.should == result
    end

    it "should strip namespaces from Hash keys" do
      soap_response = { "ns:userResponse" => { "ns2:id" => "666" } }
      result = { :user_response => { :id => "666" } }

      soap_response.map_soap_response.should == result
    end

    context "with Savon.strip_namespaces set to false" do
      around do |example|
        Savon.strip_namespaces = false
        example.run
        Savon.strip_namespaces = true
      end

      it "should not strip namespaces from Hash keys" do
        soap_response = { "ns:userResponse" => { "ns2:id" => "666" } }
        result = { "ns:user_response" => { "ns2:id" => "666" } }

        soap_response.map_soap_response.should == result
      end
    end

    it "should convert Hash keys and values in Arrays" do
      soap_response = { "response" => [{ "name" => "dude" }, { "name" => "gorilla" }] }
      result = { :response=> [{ :name => "dude" }, { :name => "gorilla" }] }

      soap_response.map_soap_response.should == result
    end

    it "should convert xsi:nil values to nil Objects" do
      soap_response = { "userResponse" => { "xsi:nil" => "true" } }
      result = { :user_response => nil }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash values matching the xs:dateTime format into DateTime Objects" do
      soap_response = { "response" => { "at" => "2012-03-22T16:22:33+00:00" } }
      result = { :response => { :at => DateTime.new(2012, 03, 22, 16, 22, 33) } }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash values matching 'true' to TrueClass" do
      soap_response = { "response" => { "active" => "false" } }
      result = { :response => { :active => false } }

      soap_response.map_soap_response.should == result
    end

    it "should convert Hash values matching 'false' to FalseClass" do
      soap_response = { "response" => { "active" => "true" } }
      result = { :response => { :active => true } }

      soap_response.map_soap_response.should == result
    end

    it "should convert namespaced entries to array elements" do
      soap_response = {
        "history" => {
          "ns10:case" => { "ns10:name" => "a_name" },
          "ns11:case" => { "ns11:name" => "another_name" }
        }
      }
      
      result = {
        :history => {
          :case => [{ :name => "a_name" }, { :name => "another_name" }]
        }
      }
      
      soap_response.map_soap_response.should == result
    end
  end

end
