# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "..", "helper")

class SavonWsdlTest < Test::Unit::TestCase

  def setup
    @some_factory = WsdlFactory.new
    @some_wsdl = Savon::Wsdl.new(some_uri, http_mock(@some_factory.build))

    @choice_factory = WsdlFactory.new(
      :service_methods => {"findUser" => ["credential"]},
      :choice_elements => {"credential" => ["id", "email"]}
    )
    @choice_wsdl = Savon::Wsdl.new(some_uri, http_mock(@choice_factory.build))
  end

  def test_namespace_uri_with_some_wsdl_returns_namespace_uri
    assert_equal @some_factory.namespace_uri, @some_wsdl.namespace_uri
  end

  def test_service_methods_with_auth_wsdl_returns_service_methods
    assert_equal @some_factory.service_methods.keys, @some_wsdl.service_methods
  end

  def test_choice_elements_with_auth_wsdl_returns_empty_array
    assert_equal @some_factory.choice_elements.keys, @some_wsdl.choice_elements
  end

  def test_choice_elements_with_choice_wsdl_returns_choice_elements
    assert_equal @choice_factory.choice_elements["credential"], @choice_wsdl.choice_elements
  end

  def test_to_s_with_auth_wsdl_returns_http_response_body
    assert_equal @some_factory.build, @some_wsdl.to_s
  end

  # Returns some URI
  def some_uri
    URI("http://example.com")
  end

  # Returns a Net::HTTP mock which returns a Net::HTTPResponse mock.
  def http_mock(response_body)
    http_mock = mock()
    http_mock.expects(:get).returns(response_mock(response_body))
    http_mock
  end

  # Returns a Net::HTTPResponse mock using the given response_body fixture.
  def response_mock(response_body)
    response_mock = mock('Net::HTTPResponse')
    response_mock.stubs(
      :code => '200', :message => "OK", :content_type => "text/html",
      :body => response_body
    )
    response_mock
  end

end