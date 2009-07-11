require "rubygems"
require "test/unit"
require "mocha"
require "shoulda"
require "apricoteatsgorilla"

require File.join(File.dirname(__FILE__), "..", "lib", "savon")
require File.join(File.dirname(__FILE__), "factories", "wsdl")
require File.join(File.dirname(__FILE__), "fixtures", "soap_response")

module TestHelper

  def some_url
    "http://example.com"
  end

  def some_uri
    URI(some_url)
  end

  def service_http_mock(response_body)
    http_mock = mock()
    http_mock.expects(:get).returns(response_mock(WsdlFactory.new.build))
    http_mock.expects(:request_post).returns(response_mock(response_body))
    http_mock
  end

  def http_mock(response_body)
    http_mock = mock()
    http_mock.expects(:get).returns(response_mock(response_body))
    http_mock
  end

  def response_mock(response_body)
    build_response_mock("200", "OK", response_body)
  end

  def response_fault_mock
    build_response_mock("404", "NotFound")
  end

  def build_response_mock(code, message, body = nil)
    response_mock = mock("Net::HTTPResponse")
    response_mock.stubs(
      :code => code, :message => message, :content_type => "text/html",
      :body => body
    )
    response_mock
  end

end