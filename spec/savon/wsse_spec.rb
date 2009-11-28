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

  describe "wsse?" do
    it "returns true in case WSSE credentials are available via options" do
      @wsse.options = wsse_options
      @wsse.wsse?.should be_true
    end

    it "returns false in case WSSE credentials are missing or incomplete" do
      @wsse.wsse?.should be_false
      new_wsse_instance(:wsse => { :username => "user" }).wsse?.should be_false
      new_wsse_instance(:wsse => { :password => "secret" }).wsse?.should be_false
    end
  end

  describe "wsse_header" do
    it "returns the XML for a WSSE authentication header" do
      @wsse.options = wsse_options
      wsse_header = @wsse.wsse_header Builder::XmlMarkup.new

      wsse_header.should include_security_namespaces
      wsse_header.should include @wsse_username
      wsse_header.should include @wsse_password
    end

    it "returns the XML for a WSSE digest header if specified via options" do
      @wsse.options = wsse_options :for_digest
      wsse_header = @wsse.wsse_header Builder::XmlMarkup.new

      wsse_header.should include_security_namespaces
      wsse_header.should include @wsse_username
      wsse_header.should_not include @wsse_password
    end

    def include_security_namespaces
      simple_matcher("include security namespaces") do |given|
        given.should include Savon::WSSE::WSENamespace
        given.should include Savon::WSSE::WSUNamespace
      end
    end
  end

end
