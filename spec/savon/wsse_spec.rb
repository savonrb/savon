require "spec_helper"

describe Savon::WSSE do
  let(:wsse) { Savon::WSSE.new }

  it "should contain the namespace for WS Security Secext" do
    Savon::WSSE::WSENamespace.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  end

  it "should contain the namespace for WS Security Utility" do
    Savon::WSSE::WSUNamespace.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  end

  it "should contain the namespace for the PasswordText type" do
    Savon::WSSE::PasswordTextURI.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
  end

  it "should contain the namespace for the PasswordDigest type" do
    Savon::WSSE::PasswordDigestURI.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
  end

  describe "#credentials" do
    it "should set the username" do
      wsse.credentials "username", "password"
      wsse.username.should == "username"
    end

    it "should set the password" do
      wsse.credentials "username", "password"
      wsse.password.should == "password"
    end

    it "should default to set digest to false" do
      wsse.credentials "username", "password"
      wsse.should_not be_digest
    end

    it "should set digest to true if specified" do
      wsse.credentials "username", "password", :digest
      wsse.should be_digest
    end
  end

  describe "#username" do
    it "should set the username" do
      wsse.username = "username"
      wsse.username.should == "username"
    end
  end

  describe "#password" do
    it "should set the password" do
      wsse.password = "password"
      wsse.password.should == "password"
    end
  end

  describe "#digest" do
    it "should default to false" do
      wsse.should_not be_digest
    end

    it "should specify whether to use digest auth" do
      wsse.digest = true
      wsse.should be_digest
    end
  end

  describe "#to_xml" do
    context "with no credentials" do
      it "should return an empty String" do
        wsse.to_xml.should == ""
      end
    end

    context "with only a username" do
      before { wsse.username = "username" }

      it "should return an empty String" do
        wsse.to_xml.should == ""
      end
    end

    context "with only a password" do
      before { wsse.password = "password" }

      it "should return an empty String" do
        wsse.to_xml.should == ""
      end
    end

    context "with credentials" do
      before { wsse.credentials "username", "password" }

      it "should contain a wsse:Security tag" do
        namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
        wsse.to_xml.should include("<wsse:Security xmlns:wsse=\"#{namespace}\">")
      end

      it "should contain a wsu:Id attribute" do
        wsse.to_xml.should include('<wsse:UsernameToken wsu:Id="UsernameToken-1"')
      end

      it "should increment the wsu:Id attribute count" do
        wsse.to_xml.should include('<wsse:UsernameToken wsu:Id="UsernameToken-1"')
        wsse.to_xml.should include('<wsse:UsernameToken wsu:Id="UsernameToken-2"')
      end

      it "should contain the WSE and WSU namespaces" do
        wsse.to_xml.should include(Savon::WSSE::WSENamespace, Savon::WSSE::WSUNamespace)
      end

      it "should contain the username and password" do
        wsse.to_xml.should include("username", "password")
      end

      it "should not contain a wsse:Nonce tag" do
        wsse.to_xml.should_not match(/<wsse:Nonce>.*<\/wsse:Nonce>/)
      end

      it "should not contain a wsu:Created tag" do
        wsse.to_xml.should_not match(/<wsu:Created>.*<\/wsu:Created>/)
      end

      it "should contain the PasswordText type attribute" do
        wsse.to_xml.should include(Savon::WSSE::PasswordTextURI)
      end
    end

    context "with credentials and digest auth" do
      before { wsse.credentials "username", "password", :digest }

      it "should contain the WSE and WSU namespaces" do
        wsse.to_xml.should include(Savon::WSSE::WSENamespace, Savon::WSSE::WSUNamespace)
      end

      it "should contain the username" do
        wsse.to_xml.should include("username")
      end

      it "should not contain the (original) password" do
        wsse.to_xml.should_not include("password")
      end

      it "should contain a wsse:Nonce tag" do
        wsse.to_xml.should match(/<wsse:Nonce>\w+<\/wsse:Nonce>/)
      end

      it "should contain a wsu:Created tag" do
        wsse.to_xml.should match(/<wsu:Created>#{Savon::SOAP::DateTimeRegexp}.+<\/wsu:Created>/)
      end

      it "should contain the PasswordDigest type attribute" do
        wsse.to_xml.should include(Savon::WSSE::PasswordDigestURI)
      end
    end

    context "with #timestamp set to true" do
      before { wsse.timestamp = true }

      it "should contain a wsse:Timestamp node" do
        wsse.to_xml.should include('<wsse:Timestamp wsu:Id="Timestamp-1" ' +
          'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">')
      end

      it "should contain a wsu:Created node defaulting to Time.now" do
        created_at = Time.now
        Timecop.freeze created_at do
          wsse.to_xml.should include("<wsu:Created>#{created_at.xs_datetime}</wsu:Created>")
        end
      end

      it "should contain a wsu:Expires node defaulting to Time.now + 60 seconds" do
        created_at = Time.now
        Timecop.freeze created_at do
          wsse.to_xml.should include("<wsu:Expires>#{(created_at + 60).xs_datetime}</wsu:Expires>")
        end
      end
    end

    context "with #created_at" do
      before { wsse.created_at = Time.now + 86400 }

      it "should contain a wsu:Created node with the given time" do
        wsse.to_xml.should include("<wsu:Created>#{wsse.created_at.xs_datetime}</wsu:Created>")
      end

      it "should contain a wsu:Expires node set to #created_at + 60 seconds" do
        wsse.to_xml.should include("<wsu:Expires>#{(wsse.created_at + 60).xs_datetime}</wsu:Expires>")
      end
    end

    context "with #expires_at" do
      before { wsse.expires_at = Time.now + 86400 }

      it "should contain a wsu:Created node defaulting to Time.now" do
        created_at = Time.now
        Timecop.freeze created_at do
          wsse.to_xml.should include("<wsu:Created>#{created_at.xs_datetime}</wsu:Created>")
        end
      end

      it "should contain a wsu:Expires node set to the given time" do
        wsse.to_xml.should include("<wsu:Expires>#{wsse.expires_at.xs_datetime}</wsu:Expires>")
      end
    end

    context "whith credentials and timestamp" do
      before do
        wsse.credentials "username", "password"
        wsse.timestamp = true
      end

      it "should contain a wsu:Created node" do
        wsse.to_xml.should include("<wsu:Created>")
      end

      it "should contain a wsu:Expires node" do
        wsse.to_xml.should include("<wsu:Expires>")
      end

      it "should contain the username and password" do
        wsse.to_xml.should include("username", "password")
      end
    end
  end

end
