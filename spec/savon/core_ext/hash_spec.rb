require "spec_helper"

describe Hash do

  describe "find_regexp" do
    before do
      @soap_fault_hash = { "soap:Envelope" => { "soap:Body" => { "soap:Fault" => {
        "faultcode" => "soap:Server", "faultstring" => "Fault occurred while processing."
      } } } }
    end

    it "returns an empty Hash in case it did not find the specified value" do
      result = @soap_fault_hash.find_regexp "soap:Fault"

      result.should be_a Hash
      result.should be_empty
    end

    it "returns the value of the last Regexp filter found in the Hash" do
      @soap_fault_hash.find_regexp([".+:Envelope", ".+:Body"]).
        should == @soap_fault_hash["soap:Envelope"]["soap:Body"]

      @soap_fault_hash.find_regexp([/.+:Envelope/, /.+:Body/, /.+Fault/]).
        should == @soap_fault_hash["soap:Envelope"]["soap:Body"]["soap:Fault"]
    end
  end

  describe "to_soap_xml" do
    describe "returns SOAP request compatible XML" do
      it "for a simple Hash" do
        { :some => "user" }.to_soap_xml.should == "<some>user</some>"
      end

      it "for a nested Hash" do
        { :some => { :new => "user" } }.to_soap_xml.
          should == "<some><new>user</new></some>"
      end

      it "for a Hash with multiple keys" do
        soap_xml = { :all => "users", :before => "whatever" }.to_soap_xml

        soap_xml.should include "<all>users</all>"
        soap_xml.should include "<before>whatever</before>"
      end

      it "for a Hash containing an Array" do
        { :some => ["user", "gorilla"] }.to_soap_xml.
          should == "<some>user</some><some>gorilla</some>"
      end

      it "for a Hash containing an Array of Hashes" do
        { :some => [{ :new => "user" }, { :old => "gorilla" }] }.to_soap_xml.
          should == "<some><new>user</new></some><some><old>gorilla</old></some>"
      end
    end

    it "converts Hash key Symbols to lowerCamelCase" do
      { :find_or_create => "user" }.to_soap_xml.
        should == "<findOrCreate>user</findOrCreate>"
    end

    it "does not convert Hash key Strings" do
      { "find_or_create" => "user" }.to_soap_xml.
        should == "<find_or_create>user</find_or_create>"
    end

    it "converts DateTime objects to xs:dateTime compliant Strings" do
      { :before => UserFixture.datetime_object }.to_soap_xml.
        should == "<before>" << UserFixture.datetime_string << "</before>"
    end

    it "converts Objects responding to to_datetime to xs:dateTime compliant Strings" do
      singleton = Object.new
      def singleton.to_datetime
        UserFixture.datetime_object
      end

      { :before => singleton }.to_soap_xml.
        should == "<before>" << UserFixture.datetime_string << "</before>"
    end

    it "calls to_s on Strings even if they respond to to_datetime" do
      singleton = "gorilla"
      singleton.expects( :to_s ).returns singleton
      singleton.expects( :to_datetime ).never

      { :name => singleton }.to_soap_xml.should == "<name>gorilla</name>"
    end

    it "call to_s on any other Object" do
      [666, true, false, nil].each do |object|
        { :some => object }.to_soap_xml.should == "<some>#{object}</some>"
      end
    end
  end

  describe "map_soap_response" do
    it "converts Hash key Strings to snake_case Symbols" do
      { "userResponse" => { "accountStatus" => "active" } }.map_soap_response.
        should == { :user_response => { :account_status => "active" } }
    end

    it "strips namespaces from Hash keys" do
      { "ns:userResponse" => { "ns2:id" => "666" } }.map_soap_response.
        should == { :user_response => { :id => "666" } }
    end

    it "converts Hash keys and values in Arrays" do
      { "response" => [{ "name" => "dude" }, { "name" => "gorilla" }] }.map_soap_response.
        should == { :response=> [{ :name => "dude" }, { :name => "gorilla" }] }
    end

    it "converts xsi:nil values to nil Objects" do
      { "userResponse" => { "xsi:nil" => "true" } }.map_soap_response.
        should == { :user_response => nil }
    end

    it "converts Hash values matching the xs:dateTime format into DateTime Objects" do
      { "response" => { "at" => UserFixture.datetime_string } }.map_soap_response.
        should == { :response => { :at => UserFixture.datetime_object } }
    end

    it "converts Hash values matching 'true' to TrueClass" do
      { "response" => { "active" => "false" } }.map_soap_response.
        should == { :response => { :active => false } }
    end

    it "converts Hash values matching 'false' to FalseClass" do
      { "response" => { "active" => "true" } }.map_soap_response.
        should == { :response => { :active => true } }
    end
  end

end
