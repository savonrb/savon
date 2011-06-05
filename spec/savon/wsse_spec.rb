require "spec_helper"

describe Savon::WSSE do
  let(:wsse) { Savon::WSSE.new }

  it "contains the namespace for WS Security Secext" do
    Savon::WSSE::WSENamespace.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
  end

  it "contains the namespace for WS Security Utility" do
    Savon::WSSE::WSUNamespace.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
  end

  it "contains the namespace for the PasswordText type" do
    Savon::WSSE::PasswordTextURI.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText"
  end

  it "contains the namespace for the PasswordDigest type" do
    Savon::WSSE::PasswordDigestURI.should ==
      "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordDigest"
  end

  describe "#credentials" do
    it "sets the username" do
      wsse.credentials "username", "password"
      wsse.username.should == "username"
    end

    it "sets the password" do
      wsse.credentials "username", "password"
      wsse.password.should == "password"
    end

    it "defaults to set digest to false" do
      wsse.credentials "username", "password"
      wsse.should_not be_digest
    end

    it "sets digest to true if specified" do
      wsse.credentials "username", "password", :digest
      wsse.should be_digest
    end
  end

  describe "#username" do
    it "sets the username" do
      wsse.username = "username"
      wsse.username.should == "username"
    end
  end

  describe "#password" do
    it "sets the password" do
      wsse.password = "password"
      wsse.password.should == "password"
    end
  end

  describe "#digest" do
    it "defaults to false" do
      wsse.should_not be_digest
    end

    it "specifies whether to use digest auth" do
      wsse.digest = true
      wsse.should be_digest
    end
  end

  describe "#to_xml" do
    context "with no credentials" do
      it "returns an empty String" do
        wsse.to_xml.should == ""
      end
    end

    context "with only a username" do
      before { wsse.username = "username" }

      it "returns an empty String" do
        wsse.to_xml.should == ""
      end
    end

    context "with only a password" do
      before { wsse.password = "password" }

      it "returns an empty String" do
        wsse.to_xml.should == ""
      end
    end

    context "with credentials" do
      before { wsse.credentials "username", "password" }

      it "contains a wsse:Security tag" do
        namespace = "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
        wsse.to_xml.should include("<wsse:Security xmlns:wsse=\"#{namespace}\">")
      end

      it "contains a wsu:Id attribute" do
        wsse.to_xml.should include('<wsse:UsernameToken wsu:Id="UsernameToken-1"')
      end

      it "increments the wsu:Id attribute count" do
        wsse.to_xml.should include('<wsse:UsernameToken wsu:Id="UsernameToken-1"')
        wsse.to_xml.should include('<wsse:UsernameToken wsu:Id="UsernameToken-2"')
      end

      it "contains the WSE and WSU namespaces" do
        wsse.to_xml.should include(Savon::WSSE::WSENamespace, Savon::WSSE::WSUNamespace)
      end

      it "contains the username and password" do
        wsse.to_xml.should include("username", "password")
      end

      it "does not contain a wsse:Nonce tag" do
        wsse.to_xml.should_not match(/<wsse:Nonce>.*<\/wsse:Nonce>/)
      end

      it "does not contain a wsu:Created tag" do
        wsse.to_xml.should_not match(/<wsu:Created>.*<\/wsu:Created>/)
      end

      it "contains the PasswordText type attribute" do
        wsse.to_xml.should include(Savon::WSSE::PasswordTextURI)
      end
    end

    context "with credentials and digest auth" do
      before { wsse.credentials "username", "password", :digest }

      it "contains the WSE and WSU namespaces" do
        wsse.to_xml.should include(Savon::WSSE::WSENamespace, Savon::WSSE::WSUNamespace)
      end

      it "contains the username" do
        wsse.to_xml.should include("username")
      end

      it "does not contain the (original) password" do
        wsse.to_xml.should_not include("password")
      end

      it "contains a wsse:Nonce tag" do
        wsse.to_xml.should match(/<wsse:Nonce>\w+<\/wsse:Nonce>/)
      end

      it "contains a wsu:Created tag" do
        datetime_regexp = /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/
        wsse.to_xml.should match(/<wsu:Created>#{datetime_regexp}.+<\/wsu:Created>/)
      end

      it "contains the PasswordDigest type attribute" do
        wsse.to_xml.should include(Savon::WSSE::PasswordDigestURI)
      end
    end

    context "with #timestamp set to true" do
      before { wsse.timestamp = true }

      it "contains a wsse:Timestamp node" do
        wsse.to_xml.should include('<wsu:Timestamp wsu:Id="Timestamp-1" ' +
          'xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd">')
      end

      it "contains a wsu:Created node defaulting to Time.now" do
        created_at = Time.now
        Timecop.freeze created_at do
          wsse.to_xml.should include("<wsu:Created>#{created_at.xs_datetime}</wsu:Created>")
        end
      end

      it "contains a wsu:Expires node defaulting to Time.now + 60 seconds" do
        created_at = Time.now
        Timecop.freeze created_at do
          wsse.to_xml.should include("<wsu:Expires>#{(created_at + 60).xs_datetime}</wsu:Expires>")
        end
      end
    end

    context "with #created_at" do
      before { wsse.created_at = Time.now + 86400 }

      it "contains a wsu:Created node with the given time" do
        wsse.to_xml.should include("<wsu:Created>#{wsse.created_at.xs_datetime}</wsu:Created>")
      end

      it "contains a wsu:Expires node set to #created_at + 60 seconds" do
        wsse.to_xml.should include("<wsu:Expires>#{(wsse.created_at + 60).xs_datetime}</wsu:Expires>")
      end
    end

    context "with #expires_at" do
      before { wsse.expires_at = Time.now + 86400 }

      it "contains a wsu:Created node defaulting to Time.now" do
        created_at = Time.now
        Timecop.freeze created_at do
          wsse.to_xml.should include("<wsu:Created>#{created_at.xs_datetime}</wsu:Created>")
        end
      end

      it "contains a wsu:Expires node set to the given time" do
        wsse.to_xml.should include("<wsu:Expires>#{wsse.expires_at.xs_datetime}</wsu:Expires>")
      end
    end

    context "whith credentials and timestamp" do
      before do
        wsse.credentials "username", "password"
        wsse.timestamp = true
      end

      it "contains a wsu:Created node" do
        wsse.to_xml.should include("<wsu:Created>")
      end

      it "contains a wsu:Expires node" do
        wsse.to_xml.should include("<wsu:Expires>")
      end

      it "contains the username and password" do
        wsse.to_xml.should include("username", "password")
      end
    end
  end

end
