require "spec_helper"

describe Savon::WSSE do
  before do
    Savon::WSSE.username, Savon::WSSE.password, Savon::WSSE.digest = nil, nil, false
    @wsse, @username, @password = Savon::WSSE.new, "gorilla", "secret"
  end

  it "contains the namespace for WS Security Secext" do
    Savon::WSSE::WSENamespace.should be_a(String)
    Savon::WSSE::WSENamespace.should_not be_empty
  end

  it "contains the namespace for WS Security Utility" do
    Savon::WSSE::WSUNamespace.should be_a(String)
    Savon::WSSE::WSUNamespace.should_not be_empty
  end

  it "defaults to nil for the WSSE username (global setting)" do
    Savon::WSSE.username.should be_nil
  end

  it "has both getter and setter for the WSSE username (global setting)" do
    Savon::WSSE.username = "gorilla"
    Savon::WSSE.username.should == "gorilla"
  end

  it "defaults to nil for the WSSE password (global setting)" do
    Savon::WSSE.password.should be_nil
  end

  it "has both getter and setter for the WSSE password (global setting)" do
    Savon::WSSE.password = "secret"
    Savon::WSSE.password.should == "secret"
  end

  it "defaults to nil for whether to use WSSE digest (global setting)" do
    Savon::WSSE.digest?.should be_false
  end

  it "has both getter and setter for whether to use WSSE digest (global setting)" do
    Savon::WSSE.digest = true
    Savon::WSSE.digest?.should == true
  end

  it "defaults to nil for the WSSE username" do
    @wsse.username.should be_nil
  end

  it "has both getter and setter for the WSSE username" do
    @wsse.username = "gorilla"
    @wsse.username.should == "gorilla"
  end

  it "defaults to nil for the WSSE password" do
    @wsse.password.should be_nil
  end

  it "has both getter and setter for the WSSE password" do
    @wsse.password = "secret"
    @wsse.password.should == "secret"
  end

  it "defaults to nil for whether to use WSSE digest" do
    @wsse.digest?.should be_false
  end

  it "has both getter and setter for whether to use WSSE digest" do
    @wsse.digest = true
    @wsse.digest?.should == true
  end

  describe "header" do
    describe "returns the XML for a WSSE authentication header" do
      it "with WSSE credentials specified" do
        @wsse.username = @username
        @wsse.password = @password
        header = @wsse.header

        header.should include_security_namespaces
        header.should include(@username)
        header.should include(@password)
        header.should include(Savon::WSSE::PasswordTextURI)
      end

      it "with WSSE credentials specified via defaults" do
        Savon::WSSE.username = @username
        Savon::WSSE.password = @password
        header = @wsse.header

        header.should include_security_namespaces
        header.should include(@username)
        header.should include(@password)
        header.should include(Savon::WSSE::PasswordTextURI)
      end
    end

    describe "returns the XML for a WSSE digest header if specified" do
      it "via accessors" do
        @wsse.username = @username
        @wsse.password = @password
        @wsse.digest = true
        header = @wsse.header
  
        header.should include_security_namespaces
        header.should include(@username)
        header.should_not include(@password)
        header.should include(Savon::WSSE::PasswordDigestURI)
      end

      it "via defaults" do
        @wsse.username = @username
        @wsse.password = @password
        Savon::WSSE.digest = true
        header = @wsse.header
  
        header.should include_security_namespaces
        header.should include(@username)
        header.should_not include(@password)
        header.should include(Savon::WSSE::PasswordDigestURI)
      end
    end

    def include_security_namespaces
      simple_matcher("include security namespaces") do |given|
        given.should include(Savon::WSSE::WSENamespace)
        given.should include(Savon::WSSE::WSUNamespace)
      end
    end
  end

end
