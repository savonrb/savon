require "spec_helper"

describe Savon do

  describe ".configure" do
    around do |example|
      Savon.reset_config!
      example.run
      Savon.reset_config!
      Savon.log = false  # disable logging
    end

    describe "log" do
      it "defaults to true" do
        Savon.log?.should be_true
      end

      it "sets whether to log HTTP requests" do
        Savon.configure { |config| config.log = false }
        Savon.log?.should be_false
      end
    end

    describe "logger" do
      it "sets the logger to use" do
        MyLogger = Class.new
        Savon.configure { |config| config.logger = MyLogger }
        Savon.logger.should == MyLogger
      end

      it "defaults to Logger writing to STDOUT" do
        Savon.logger.should be_a(Logger)
      end
    end

    describe "log_level" do
      it "defaults to :debug" do
        Savon.log_level.should == :debug
      end

      it "sets the log level to use" do
        Savon.configure { |config| config.log_level = :info }
        Savon.log_level.should == :info
      end
    end

    describe "raise_errors" do
      it "defaults to true" do
        Savon.raise_errors?.should be_true
      end

      it "does not raise errors when disabled" do
        Savon.raise_errors = false
        Savon.raise_errors?.should be_false
      end
    end

    describe "soap_version" do
      it "defaults to SOAP 1.1" do
        Savon.soap_version.should == 1
      end

      it "returns 2 if set to SOAP 1.2" do
        Savon.soap_version = 2
        Savon.soap_version.should == 2
      end

      it "raises in case of an invalid version" do
        lambda { Savon.soap_version = 3 }.should raise_error(ArgumentError)
      end
    end

    describe "strip_namespaces" do
      it "defaults to true" do
        Savon.strip_namespaces?.should == true
      end

      it "does not strip namespaces when set to false" do
        Savon.strip_namespaces = false
        Savon.strip_namespaces?.should == false
      end
    end
  end

end
