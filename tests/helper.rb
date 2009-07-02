require 'rubygems'
require 'test/unit'
require 'mocha'
require 'shoulda'
require "apricoteatsgorilla"

["service", "wsdl", "response"].each do |file|
  require File.join(File.dirname(__FILE__), "..", "lib", "savon", file)
end

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
    response_mock = mock('Net::HTTPResponse')
    response_mock.stubs(
      :code => '200', :message => "OK", :content_type => "text/html",
      :body => response_body
    )
    response_mock
  end

end