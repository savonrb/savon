require "spec_helper"

describe Savon::WSSE do
  before do
    Savon::WSSE.username = nil
    Savon::WSSE.password = nil
    Savon::WSSE.digest = false

    @wsse = Savon::WSSE.new
    @username, @password = "gorilla", "secret"
  end

  describe "WSENamespace" do
    it "contains namespace for WS Security Secext" do
      Savon::WSSE::WSENamespace.should be_a String
      Savon::WSSE::WSENamespace.should_not be_empty
    end
  end

  describe "WSUNamespace" do
    it "contains namespace for WS Security Utility" do
      Savon::WSSE::WSUNamespace.should be_a String
      Savon::WSSE::WSUNamespace.should_not be_empty
    end
  end

  describe "@username" do
    it "defaults to nil" do
      Savon::WSSE.username.should be_nil
    end

    it "has accessor methods" do
      Savon::WSSE.username = "gorilla"
      Savon::WSSE.username.should == "gorilla"
    end
  end

  describe "@password" do
    it "defaults to nil" do
      Savon::WSSE.password.should be_nil
    end

    it "has accessor methods" do
      Savon::WSSE.password = "secret"
      Savon::WSSE.password.should == "secret"
    end
  end

  describe "@digest" do
    it "defaults to false" do
      Savon::WSSE.digest?.should be_false
    end

    it "has accessor methods" do
      Savon::WSSE.digest = true
      Savon::WSSE.digest?.should == true
    end
  end

  describe "username" do
    it "defaults to nil" do
      @wsse.username.should be_nil
    end

    it "has accessor methods" do
      @wsse.username = "gorilla"
      @wsse.username.should == "gorilla"
    end
  end

  describe "password" do
    it "defaults to nil" do
      @wsse.password.should be_nil
    end

    it "has accessor methods" do
      @wsse.password = "secret"
      @wsse.password.should == "secret"
    end
  end

  describe "digest" do
    it "defaults to false" do
      @wsse.digest?.should be_false
    end

    it "has accessor methods" do
      @wsse.digest = true
      @wsse.digest?.should == true
    end
  end

  describe "header" do
    describe "returns the XML for a WSSE authentication header" do
      it "with WSSE credentials specified" do
        @wsse.username = @username
        @wsse.password = @password
        header = @wsse.header

        header.should include_security_namespaces
        header.should include @username
        header.should include @password
      end

      it "with WSSE credentials specified via defaults" do
        Savon::WSSE.username = @username
        Savon::WSSE.password = @password
        header = @wsse.header

        header.should include_security_namespaces
        header.should include @username
        header.should include @password
      end
    end

    describe "returns the XML for a WSSE digest header if specified" do
      it "via accessors" do
        @wsse.username = @username
        @wsse.password = @password
        @wsse.digest = true
        header = @wsse.header
  
        header.should include_security_namespaces
        header.should include @username
        header.should_not include @password
      end

      it "via defaults" do
        @wsse.username = @username
        @wsse.password = @password
        Savon::WSSE.digest = true
        header = @wsse.header
  
        header.should include_security_namespaces
        header.should include @username
        header.should_not include @password
      end
    end

    def include_security_namespaces
      simple_matcher("include security namespaces") do |given|
        given.should include Savon::WSSE::WSENamespace
        given.should include Savon::WSSE::WSUNamespace
      end
    end
  end

end
