# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "..", "helper")

class SavonResponseTest < Test::Unit::TestCase
  include SoapResponseFixture

  context "Savon::Response with some SOAP response" do
    setup do
      ApricotEatsGorilla.sort_keys = true
      @response = Savon::Response.new(response_mock(some_soap_response))
    end

    should "return a Hash on to_hash" do
      assert_kind_of Hash, @response.to_hash
    end

    should "return a Hash equal to the response on to_hash" do
      assert_equal ApricotEatsGorilla(some_soap_response, "//return"), @response.to_hash
    end

    should "return the raw XML response on to_s" do
      assert_equal some_soap_response, @response.to_s
    end
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