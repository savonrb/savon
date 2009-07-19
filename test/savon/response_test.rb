require File.join(File.dirname(__FILE__), "..", "helper")

class SavonResponseTest < Test::Unit::TestCase

  include TestHelper
  include SoapResponseFixture

  context "A Savon::Response instance" do

    context "initialized with a Net::HTTPResponse containing a successful SOAP response" do
      setup do
        ApricotEatsGorilla.sort_keys = true
        Savon::Response.core_methods_to_shadow = [:id] # set to default
        @response = Savon::Response.new response_mock(some_soap_response)
      end

      should "return that the request was successful" do
        assert_equal true, @response.success?
        assert_equal false, @response.error?
      end

      should "return nil for error_code and error_message" do
        assert_nil @response.error_code
        assert_nil @response.error_message
      end

      should "return the SOAP response XML when calling to_s" do
        assert_equal some_soap_response, @response.to_s
      end

      should "return the Hash translated from the SOAP response XML when calling to_hash" do
        assert_kind_of Hash, @response.to_hash
        assert_equal some_response_hash, @response.to_hash
      end

      should "return a Hash for Hash values accessed through []" do
        assert_kind_of Hash, @response[:authentication]
        assert_equal some_response_hash[:authentication], @response[:authentication]
      end

      should "return the actual value for values other than Hashes through []" do
        assert_kind_of TrueClass, @response[:success]
        assert_kind_of Array, @response[:tokens]
        assert_equal some_response_hash[:success], @response[:success]
        assert_equal some_response_hash[:tokens], @response[:tokens]
      end

      should "return nil when trying to access a not-existing key from the Hash" do
        assert_nil @response.some_undefined_key
      end

      should "return a Savon::Response for Hash values accessed through method_missing" do
        assert_kind_of Savon::Response, @response.authentication
      end

      should "return the actual value for values other than Hashes through method_missing" do
        assert_kind_of TrueClass, @response.success
        assert_kind_of Array, @response.tokens
        assert_equal some_response_hash[:success], @response.success
        assert_equal some_response_hash[:tokens], @response.tokens
      end

      should "by default shadow the :id method if it was found in the Hash" do
        response_with_id = Savon::Response.new response_mock(soap_response_with_id)
        assert_equal response_hash_with_id[:id], response_with_id.id
      end

      should "shadow user-specified core methods in case they were found in the Hash" do
        Savon::Response.core_methods_to_shadow = [:inspect]
        response_with_inspect = Savon::Response.new response_mock(soap_response_with_inspect)

        assert_equal response_hash_with_inspect[:inspect], response_with_inspect.inspect
      end
    end

    context "initialized with a Hash" do
      setup do
        ApricotEatsGorilla.sort_keys = true
        Savon::Response.core_methods_to_shadow = [:id] # set to default
        @response = Savon::Response.new some_response_hash
      end

      should "return nil for HTTP::Response-specific methods" do
        assert_nil @response.success?
        assert_nil @response.error?
        assert_nil @response.error_code
        assert_nil @response.error_message
        assert_nil @response.to_s
      end

      should "return the given Hash when calling to_hash" do
        assert_kind_of Hash, @response.to_hash
        assert_equal some_response_hash, @response.to_hash
      end

      should "return a Hash for Hash values accessed through []" do
        assert_kind_of Hash, @response[:authentication]
        assert_equal some_response_hash[:authentication], @response[:authentication]
      end

      should "return the actual value for values other than Hashes through []" do
        assert_kind_of TrueClass, @response[:success]
        assert_kind_of Array, @response[:tokens]
        assert_equal some_response_hash[:success], @response[:success]
        assert_equal some_response_hash[:tokens], @response[:tokens]
      end

      should "return a Savon::Response for Hash values accessed through method_missing" do
        assert_kind_of Savon::Response, @response.authentication
      end

      should "return the actual value for values other than Hashes through method_missing" do
        assert_kind_of TrueClass, @response.success
        assert_kind_of Array, @response.tokens
        assert_equal some_response_hash[:success], @response.success
        assert_equal some_response_hash[:tokens], @response.tokens
      end

      should "by default shadow the :id method if it was found in the Hash" do
        hash_with_id = response_hash_with_id
        @response = Savon::Response.new hash_with_id
        assert_equal hash_with_id[:id], @response.id
      end

      should "shadow user-specified core methods in case they were found in the Hash" do
        Savon::Response.core_methods_to_shadow = [:inspect]
        response_with_inspect = Savon::Response.new response_hash_with_inspect

        assert_equal response_hash_with_inspect[:inspect], response_with_inspect.inspect
      end
    end

  end

end