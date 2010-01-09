require "spec_helper"

describe Hash do

  describe "find_soap_body" do
    it "returns the content from the 'soap:Body' element" do
      { "soap:Envelope" => { "soap:Body" => "content" } }.find_soap_body.should == "content"
    end

    it "returns an empty Hash in case the 'soap:Body' element could not be found" do
      { "some_hash" => "content" }.find_soap_body.should == {}
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

        soap_xml.should include("<all>users</all>")
        soap_xml.should include("<before>whatever</before>")
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
      { :before => DateTime.new(2012, 03, 22, 16, 22, 33) }.to_soap_xml.
        should == "<before>" << "2012-03-22T16:22:33" << "</before>"
    end

    it "converts Objects responding to to_datetime to xs:dateTime compliant Strings" do
      singleton = Object.new
      def singleton.to_datetime
        DateTime.new(2012, 03, 22, 16, 22, 33)
      end

      { :before => singleton }.to_soap_xml.
        should == "<before>" << "2012-03-22T16:22:33" << "</before>"
    end

    it "calls to_s on Strings even if they respond to to_datetime" do
      object = "gorilla"
      object.expects(:to_s).returns object
      object.expects(:to_datetime).never

      { :name => object }.to_soap_xml.should == "<name>gorilla</name>"
    end

    it "call to_s on any other Object" do
      [666, true, false, nil].each do |object|
        { :some => object }.to_soap_xml.should == "<some>#{object}</some>"
      end
    end

    it "preserves the order of Hash keys and values specified through :@inorder" do
      { :find_user => { :name => "Lucy", :id => 666, :@inorder => [:id, :name] } }.to_soap_xml.
        should == "<findUser><id>666</id><name>Lucy</name></findUser>"

      { :find_user => { :by_name => { :mname => "in the", :lname => "Sky", :fname => "Lucy",
        :@inorder => [:fname, :mname, :lname] } } }.to_soap_xml. should ==
        "<findUser><byName><fname>Lucy</fname><mname>in the</mname><lname>Sky</lname></byName></findUser>"
    end

    it "raises an error if the :@inorder Array does not match the Hash keys" do
      lambda { { :name => "Lucy", :id => 666, :@inorder => [:name] }.to_soap_xml }.
        should raise_error(RuntimeError)

      lambda { { :by_name => { :name => "Lucy", :lname => "Sky", :@inorder => [:mname, :name] } }.to_soap_xml }.
        should raise_error(RuntimeError)
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
      { "response" => { "at" => "2012-03-22T16:22:33" } }.map_soap_response.
        should == { :response => { :at => DateTime.new(2012, 03, 22, 16, 22, 33) } }
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
