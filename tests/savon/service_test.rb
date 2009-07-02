# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "..", "helper")

class SavonServiceTest < Test::Unit::TestCase
  include SoapResponseFixture

  context "Savon::Service" do
    setup do
      @service = Savon::Service.new(some_url)
      @service.http = http_mock(some_soap_response)
      @result = @service.findById
    end

    should "return a Savon::Response object containing the given response" do
      assert_kind_of Savon::Response, @result
      assert_equal some_soap_response, @result.to_s
    end

    should "return an instance of Savon::Wsdl on wsdl" do
      assert_kind_of Savon::Wsdl, @service.wsdl
    end

    should "raise an ArgumentError when called with an invalid action" do
      assert_raise ArgumentError do
        @service.somethingCrazy
      end
    end
  end

  def some_url
    "http://example.com"
  end

  def some_uri
    URI(some_url)
  end

  def http_mock(response_body)
    http_mock = mock()
    http_mock.expects(:get).returns(response_mock(WsdlFactory.new.build))
    http_mock.expects(:request_post).returns(response_mock(response_body))
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