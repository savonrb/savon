require "spec_helper"

describe Savon::Service do
  before { @proxy = Savon::Service.new SpecHelper.some_endpoint }

  describe "method_missing" do

    it "converts parameter keys specified as Symbols to lowerCamelCase" do
      @proxy.find_user :totally_rad => { "$" => "true" }
      @proxy.http_request.body.should include "<totallyRad>true</totallyRad>"
    end

    it "does not convert parameter keys specified as Strings" do
      @proxy.find_user "totally_rad" => { "$" => "true" }
      @proxy.http_request.body.should include "<totally_rad>true</totally_rad>"
    end

    it "converts DateTime parameter values to SOAP datetime Strings" do
      @proxy.find_user :before => { "$" => DateTime.new(2012, 6, 11, 10, 42, 21) }
      @proxy.http_request.body.should include "<before>2012-06-11T10:42:21</before>"
    end

    it "converts parameter values responding to :to_datetime to SOAP datetime Strings" do
      datetime_singleton = Class.new
      def datetime_singleton.to_datetime
        DateTime.new(2012, 6, 11, 10, 42, 21)
      end

      @proxy.find_user :before => { "$" => datetime_singleton }
      @proxy.http_request.body.should include "<before>2012-06-11T10:42:21</before>"
    end

    it "converts parameter values responding to :to_s into Strings" do
      @proxy.find_user :before => { "$" => 2012 }, :with => { "$" => :superpowers }
      @proxy.http_request.body.should include "<before>2012</before>", "<with>superpowers</with>"
    end

  end

end