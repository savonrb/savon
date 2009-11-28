require "spec_helper"

describe Savon::Validation do
  before do
    @validation = Class.new
    class << @validation
      include Savon::Validation
    end
  end

  describe "validate!" do
    describe ":endpoint" do
      it "returns true for valid endpoints" do
        @validation.validate!(:endpoint, "http://example.com").should be_true
      end

      it "raises an ArgumentError in case of invalid endpoints" do
        lambda { @validation.validate! :endpoint, "invalid" }.
          should raise_error(ArgumentError)
      end
    end

    describe ":soap_version" do
      it "returns true for valid SOAP versions" do
        Savon::Validation::SOAPVersions.each do |soap_version|
          @validation.validate!(:soap_version, soap_version).should be_true
        end
      end

      it "raises an ArgumentError in case of invalid SOAP versions" do
        [5, 9, nil, false, "upcoming"].each do |soap_version|
          lambda { @validation.validate! :soap_version, soap_version }.
            should raise_error(ArgumentError)
        end
      end
    end

    describe ":soap_body" do
      it "returns true for Hashes" do
        @validation.validate!(:soap_body, {}).should be_true
      end

      it "returns true for Objects responding to to_s" do
        [123, "body", Time.now].each do |soap_body|
          lambda { @validation.validate!(:soap_body, soap_body) }.should be_true
        end
      end

      it "raises an ArgumentError in case of an invalid SOAP body" do
        singleton = "pretending like there is no such thing as to_s"
        def singleton.respond_to?(method)
          false
        end

        lambda { @validation.validate! :endpoint, singleton }.
          should raise_error(ArgumentError)
      end
    end

    describe ":response_process" do
      it "returns true for Objects responding to call" do
        @validation.validate!(:response_process, Proc.new {}).should be_true
      end

      it "raises an ArgumentError for an invalid response process" do
        [123, "block", [], {}].each do |response_process|
          lambda { @validation.validate! :response_process, response_process }.
            should raise_error(ArgumentError)
        end
      end
    end

    describe ":wsse_credentials" do
      it "returns true for valid WSSE credentials" do
        wsse_credentials = { :username => "user", :password => "secret" }
        @validation.validate!(:wsse_credentials, wsse_credentials).should be_true
      end

      it "returns false for invalid WSSE credentials" do
        [{ :username => "user" }, { :password => "secret" }].each do |wsse_credentials|
          lambda { @validation.validate! :wsse_credentials, wsse_credentials }.
            should raise_error(ArgumentError)
        end
      end
    end

  end
end
