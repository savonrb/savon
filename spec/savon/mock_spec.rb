require "spec_helper"
require "savon/mock/spec_helper"

describe "Savon's mock interface" do
  include Savon::SpecHelper

  before :all do
    savon.mock!
  end

  after :all do
    savon.unmock!
  end

  it "fails with an unexpected request" do
    expect { new_client.call(:authenticate) }.
      to raise_error(Savon::ExpectationError, "Unexpected request to the :authenticate operation.")
  end

  it "can verify a request and return a fixture response" do
    savon.expects(:authenticate).with(:message => { :username => "luke", :password => "secret" }).returns("<fixture/>")

    response = new_client.call(:authenticate) do
      message(:username => "luke", :password => "secret")
    end

    expect(response.http.body).to eq("<fixture/>")
  end

  context "operation" do
    it "fails when the expected SOAP operation does not match the actual one" do
      savon.expects(:logout).returns("<fixture/>")

      expect { new_client.call(:authenticate) }.
        to raise_error(Savon::ExpectationError, "Expected a request to the :logout operation.\n" \
                                                "Received a request to the :authenticate operation instead.")
    end
  end

  context "message" do
    it "fails when there is no actual message to match" do
      message = { :username => "luke" }
      savon.expects(:find_user).with(:message => message).returns("<fixture/>")

      expect { new_client.call(:find_user) }.
        to raise_error(Savon::ExpectationError, "Expected a request to the :find_user operation\n" \
                                                "  with this message: #{message.inspect}\n" \
                                                "Received a request to the :find_user operation\n" \
                                                "  with no message.")
    end

    it "fails when there is no expect but an actual message" do
      savon.expects(:find_user).returns("<fixture/>")
      message = { :username => "luke" }

      expect { new_client.call(:find_user, :message => message) }.
        to raise_error(Savon::ExpectationError, "Expected a request to the :find_user operation\n" \
                                                "  with no message.\n" \
                                                "Received a request to the :find_user operation\n" \
                                                "  with this message: #{message.inspect}")
    end
  end

  context "#returns" do
    it "accepts a Hash to specify the response code, headers and body" do
      soap_fault = Fixture.response(:soap_fault)
      response = { :code => 500, :headers => { "X-Result" => "invalid" }, :body => soap_fault }

      savon.expects(:authenticate).returns(response)
      response = new_client(:raise_errors => false).call(:authenticate)

      expect(response).to_not be_successful
      expect(response).to be_a_soap_fault

      expect(response.http.code).to eq(500)
      expect(response.http.headers).to eq("X-Result" => "invalid")
      expect(response.http.body).to eq(soap_fault)
    end
  end

  def new_client(globals = {})
    defaults = {
      :endpoint  => "http://example.com",
      :namespace => "http://v1.example.com",
      :logger    => Savon::NullLogger.new
    }

    Savon.client defaults.merge(globals)
  end

end
