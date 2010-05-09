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

  describe "to_soap_xml" do
    describe "should return SOAP request compatible XML" do
      it "for a simple Hash" do
        hash, result = { :some => "user" }, "<some>user</some>"
        hash.to_soap_xml.should == result
      end

      it "for a nested Hash" do
        hash, result = { :some => { :new => "user" } }, "<some><new>user</new></some>"
        hash.to_soap_xml.should == result
      end

      it "for a Hash with multiple keys" do
        hash = { :all => "users", :before => "whatever" }
        hash.to_soap_xml.should include("<all>users</all>", "<before>whatever</before>")
      end

      it "for a Hash containing an Array" do
        hash, result = { :some => ["user", "gorilla"] }, "<some>user</some><some>gorilla</some>"
        hash.to_soap_xml.should == result
      end

      it "for a Hash containing an Array of Hashes" do
        hash = { :some => [{ :new => "user" }, { :old => "gorilla" }] }
        result = "<some><new>user</new></some><some><old>gorilla</old></some>"

        hash.to_soap_xml.should == result
      end
    end

    it "should convert Hash key Symbols to lowerCamelCase" do
      hash, result = { :find_or_create => "user" }, "<findOrCreate>user</findOrCreate>"
      hash.to_soap_xml.should == result
    end

    it "should not convert Hash key Strings" do
      hash, result = { "find_or_create" => "user" }, "<find_or_create>user</find_or_create>"
      hash.to_soap_xml.should == result
    end

    it "should convert DateTime objects to xs:dateTime compliant Strings" do
      hash = { :before => DateTime.new(2012, 03, 22, 16, 22, 33) }
      result = "<before>2012-03-22T16:22:33Z</before>"

      hash.to_soap_xml.should == result
    end

    it "should convert Objects responding to to_datetime to xs:dateTime compliant Strings" do
      singleton = Object.new
      def singleton.to_datetime
        DateTime.new(2012, 03, 22, 16, 22, 33)
      end

      hash, result = { :before => singleton }, "<before>2012-03-22T16:22:33Z</before>"
      hash.to_soap_xml.should == result
    end

    it "should call to_s on Strings even if they respond to to_datetime" do
      object = "gorilla"
      object.expects(:to_datetime).never

      hash, result = { :name => object }, "<name>gorilla</name>"
      hash.to_soap_xml.should == result
    end

    it "should call to_s on any other Object" do
      [666, true, false, nil].each do |object|
        { :some => object }.to_soap_xml.should == "<some>#{object}</some>"
      end
    end

    it "should default to escape special characters" do
      result = { :some => { :nested => "<tag />" }, :tag => "<tag />" }.to_soap_xml
      result.should include("<tag>&lt;tag /&gt;</tag>")
      result.should include("<some><nested>&lt;tag /&gt;</nested></some>")
    end

    it "should not escape special characters for keys marked with an exclamation mark" do
      result = { :some => { :nested! => "<tag />" }, :tag! => "<tag />" }.to_soap_xml
      result.should include("<tag><tag /></tag>")
      result.should include("<some><nested><tag /></nested></some>")
    end

    it "should preserve the order of Hash keys and values specified through :order!" do
      hash = { :find_user => { :name => "Lucy", :id => 666, :order! => [:id, :name] } }
      result = "<findUser><id>666</id><name>Lucy</name></findUser>"
      hash.to_soap_xml.should == result

      hash = { :find_user => { :mname => "in the", :lname => "Sky", :fname => "Lucy", :order! => [:fname, :mname, :lname] } }
      result = "<findUser><fname>Lucy</fname><mname>in the</mname><lname>Sky</lname></findUser>"
      hash.to_soap_xml.should == result
    end

    it "should raise an error if the :order! Array does not match the Hash keys" do
      hash = { :name => "Lucy", :id => 666, :order! => [:name] }
      lambda { hash.to_soap_xml }.should raise_error(ArgumentError)

      hash = { :by_name => { :name => "Lucy", :lname => "Sky", :order! => [:mname, :name] } }
      lambda { hash.to_soap_xml }.should raise_error(ArgumentError)
    end

    it "should add attributes to Hash keys specified through :attributes!" do
      hash = { :find_user => { :person => "Lucy", :attributes! => { :person => { :id => 666 } } } }
      result = '<findUser><person id="666">Lucy</person></findUser>'
      hash.to_soap_xml.should == result

      hash = { :find_user => { :person => "Lucy", :attributes! => { :person => { :id => 666, :city => "Hamburg" } } } }
      soap_xml = hash.to_soap_xml
      soap_xml.should include('id="666"', 'city="Hamburg"')
    end

    it "should add attributes to duplicate Hash keys specified through :attributes!" do
      hash = { :find_user => { :person => ["Lucy", "Anna"], :attributes! => { :person => { :id => [1, 3] } } } }
      result = '<findUser><person id="1">Lucy</person><person id="3">Anna</person></findUser>'
      hash.to_soap_xml.should == result
      
      hash = { :find_user => { :person => ["Lucy", "Anna"], :attributes! => { :person => { :active => "true" } } } }
      result = '<findUser><person active="true">Lucy</person><person active="true">Anna</person></findUser>'
      hash.to_soap_xml.should == result
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
      soap_response = { "response" => { "at" => "2012-03-22T16:22:33" } }
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
  end

end
