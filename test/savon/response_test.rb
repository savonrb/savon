require File.join(File.dirname(__FILE__), "..", "helper")

class SavonResponseTest < Test::Unit::TestCase

  include TestHelper
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
      assert_equal ApricotEatsGorilla[some_soap_response, "//return"], @response.to_hash
    end

    should "return a Mash object on to_mash" do
      assert_kind_of Savon::Mash, @response.to_mash
    end

    should "return a Mash object equal to the response on to_mash" do
      assert_equal "secret", @response.to_mash.token
    end

    should "return the raw XML response on to_s" do
      assert_equal some_soap_response, @response.to_s
    end

    should "return 'true' on success?" do
      assert_equal true, @response.success?
    end

    should "return 'false' on fault?" do
      assert_equal false, @response.fault?
    end

    should "return 'nil' for fault" do
      assert_equal nil, @response.fault
    end

    should "return 'nil' for fault_code" do
      assert_equal nil, @response.fault_code
    end
  end

  context "Savon::Response with SOAP::Fault response" do
    setup do
      ApricotEatsGorilla.sort_keys = true
      @response = Savon::Response.new(response_mock(soap_fault_response))
    end

    should "return 'nil' on to_hash" do
      assert_equal nil, @response.to_hash
    end

    should "return 'nil' on to_mash" do
      assert_equal nil, @response.to_mash
    end

    should "return the raw XML response on to_s" do
      assert_equal soap_fault_response, @response.to_s
    end

    should "return 'false' on success?" do
      assert_equal false, @response.success?
    end

    should "return 'true' on fault?" do
      assert_equal true, @response.fault?
    end

    should "return the fault on fault" do
      assert_equal soap_fault, @response.fault
    end

    should "return the fault_code on fault_code" do
      assert_equal soap_fault_code, @response.fault_code
    end
  end

  context "Savon::Response with 404 error" do
    setup do
      ApricotEatsGorilla.sort_keys = true
      @response = Savon::Response.new(response_fault_mock)
    end

    should "return 'nil' on to_hash" do
      assert_equal nil, @response.to_hash
    end

    should "return 'nil' on to_mash" do
      assert_equal nil, @response.to_mash
    end

    should "return nil on to_s" do
      assert_equal nil, @response.to_s
    end

    should "return 'false' on success?" do
      assert_equal false, @response.success?
    end

    should "return 'true' on fault?" do
      assert_equal true, @response.fault?
    end

    should "return the fault on fault" do
      assert_equal "NotFound", @response.fault
    end

    should "return the fault_code on fault_code" do
      assert_equal "404", @response.fault_code
    end

  end

end