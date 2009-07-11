require File.join(File.dirname(__FILE__), "..", "helper")

class SavonWsdlTest < Test::Unit::TestCase

  include TestHelper

  context "Savon::Wsdl without choice elements" do
    setup do
      @some_factory = WsdlFactory.new
      @some_wsdl = Savon::Wsdl.new(some_uri, http_mock(@some_factory.build))
    end

    should "return the namespace_uri" do
      assert_equal @some_factory.namespace_uri, @some_wsdl.namespace_uri
    end

    should "return the available service_methods" do
       assert_equal @some_factory.service_methods.keys, @some_wsdl.service_methods
    end

    should "not find any choice elements, so choice_elements returns []" do
      assert_equal @some_factory.choice_elements.keys, @some_wsdl.choice_elements
    end
  end

  context "Savon::Wsdl with choice elements" do
    setup do
      @choice_factory = WsdlFactory.new(
        :service_methods => {"findUser" => ["credential"]},
        :choice_elements => {"credential" => ["id", "email"]}
      )
      @choice_wsdl = Savon::Wsdl.new(some_uri, http_mock(@choice_factory.build))
    end

    should "return the available choice elements" do
      assert_equal @choice_factory.choice_elements["credential"], @choice_wsdl.choice_elements
    end

    should "return the raw SOAP response on to_s" do
      assert_equal @choice_factory.build, @choice_wsdl.to_s
    end
  end

end