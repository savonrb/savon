require "spec_helper"

describe Wasabi::Resolver do

  describe "#resolve" do
    it "resolves remote documents" do
      HTTPI.expects(:get).returns HTTPI::Response.new(200, {}, "wsdl")
      xml = Wasabi::Resolver.new.resolve("http://example.com?wsdl")
      xml.should == "wsdl"
    end

    it "resolves local documents" do
      xml = Wasabi::Resolver.new.resolve(fixture(:authentication).path)
      xml.should == fixture(:authentication).read
    end

    it "simply returns raw XML" do
      xml = Wasabi::Resolver.new.resolve("<xml/>")
      xml.should == "<xml/>"
    end

    it "raises HTTPError when #load_from_remote gets a response error" do
      code = 404
      headers = {
        "content-type" => "text/html"
      }
      body = "<html><head><title>404 Not Found</title></head><body>Oops!</body></html>"

      failed_response = HTTPI::Response.new(code, headers, body)
      HTTPI.stubs(:get).returns(failed_response)

      expect { Wasabi::Resolver.new.resolve("http://example.com?wsdl") }.to raise_error { |error|
        error.should be_a(Wasabi::Resolver::HTTPError)
        error.message.should == "Error: #{code}"
        error.response.should == failed_response
      }
    end
  end

end
