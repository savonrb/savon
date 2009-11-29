require "spec_helper"

describe Savon::WSSE do
  before do
    @wsse = new_wsse_instance
    @wsse_username = "gorilla"
    @wsse_password = "secret"
  end

  def new_wsse_instance(credentials = {})
    wsse = Class.new
    class << wsse
      include Savon::WSSE
      attr_accessor :options
    end
    wsse.options = { :wsse => {} }
    wsse
  end

  def wsse_options(digest = false)
    { :wsse => { :username => @wsse_username,
      :password => @wsse_password, :digest => digest } }
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
      Savon::WSSE.username = nil
    end
  end

  describe "@password" do
    it "defaults to nil" do
      Savon::WSSE.password.should be_nil
    end

    it "has accessor methods" do
      Savon::WSSE.password = "secret"
      Savon::WSSE.password.should == "secret"
      Savon::WSSE.password = nil
    end
  end

  describe "@digest" do
    it "defaults to false" do
      Savon::WSSE.digest?.should be_false
    end

    it "has accessor methods" do
      Savon::WSSE.digest = true
      Savon::WSSE.digest?.should == true
      Savon::WSSE.digest = false
    end
  end

  describe "wsse?" do
    describe "returns true in case WSSE credentials are available" do
      it "via options" do
        @wsse.options = wsse_options
        @wsse.wsse?.should be_true
      end

      it "via defaults" do
        Savon::WSSE.username = "gorilla"
        Savon::WSSE.password = "secret"

        @wsse.wsse?.should be_true
      end
    end

    describe "returns false in case WSSE credentials are missing or incomplete" do
      it "via options" do
        @wsse.wsse?.should be_false

        new_wsse_instance(:wsse => { :username => @wsse_username }).wsse?.
          should be_false

        new_wsse_instance(:wsse => { :password => @wsse_password }).wsse?.
            should be_false
      end

      it "via defaults" do
        Savon::WSSE.username = @wsse_username
        @wsse.wsse?.should be_false
        
        Savon::WSSE.username = nil
        Savon::WSSE.password = @wsse_password
        @wsse.wsse?.should be_false
      end
    end
  end

  describe "wsse_header" do
    describe "returns the XML for a WSSE authentication header" do
      it "with WSSE credentials specified via options" do
        @wsse.options = wsse_options
        wsse_header = @wsse.wsse_header Builder::XmlMarkup.new

        wsse_header.should include_security_namespaces
        wsse_header.should include @wsse_username
        wsse_header.should include @wsse_password
      end

      it "with WSSE credentials specified via defaults" do
        Savon::WSSE.username = @wsse_username
        Savon::WSSE.password = @wsse_password
        wsse_header = @wsse.wsse_header Builder::XmlMarkup.new

        wsse_header.should include_security_namespaces
        wsse_header.should include @wsse_username
        wsse_header.should include @wsse_password
      end
    end

    describe "returns the XML for a WSSE digest header if specified" do
      before {}
      it "via options" do
        @wsse.options = wsse_options :for_digest
        wsse_header = @wsse.wsse_header Builder::XmlMarkup.new
  
        wsse_header.should include_security_namespaces
        wsse_header.should include @wsse_username
        wsse_header.should_not include @wsse_password
      end

      it "via defaults" do
        Savon::WSSE.digest = true
        @wsse.options = wsse_options
        wsse_header = @wsse.wsse_header Builder::XmlMarkup.new
  
        wsse_header.should include_security_namespaces
        wsse_header.should include @wsse_username
        wsse_header.should_not include @wsse_password
      end
    end

    def include_security_namespaces
      simple_matcher("include security namespaces") do |given|
        given.should include Savon::WSSE::WSENamespace
        given.should include Savon::WSSE::WSUNamespace
      end
    end
  end

  after do
    Savon::WSSE.username = nil
    Savon::WSSE.password = nil
    Savon::WSSE.digest = false
  end
end
