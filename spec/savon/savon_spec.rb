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
      it "should default to true" do
        Savon.log?.should be_true
      end

      it "should set whether to log HTTP requests" do
        Savon.configure { |config| config.log = false }
        Savon.log?.should be_false
      end
    end

    describe "logger" do
      it "should set the logger to use" do
        MyLogger = Class.new
        Savon.configure { |config| config.logger = MyLogger }
        Savon.logger.should == MyLogger
      end

      it "should default to Logger writing to STDOUT" do
        Savon.logger.should be_a(Logger)
      end
    end

    describe "log filter" do

      context "without a log filter set" do
        it "should not filter XML messages" do
          filtered_message = Savon.filtered(Fixture.response(:authentication))
          filtered_message.should == Fixture.response(:authentication)
        end

        it "should not filter non-XML messages" do
          filtered_message = Savon.filtered('This is an information message.')
          filtered_message.should == 'This is an information message.'
        end
      end

      context "with a log filter set" do
        before(:each) do
          Savon.configure { |config| config.log_filter = ['tokenHash'] }
        end

        it "should set log filter" do
          Savon.log_filter.should == ['tokenHash']
        end

        it "should filter element values" do
          filtered_value = "AAAJxA;cIedoT;mY10ExZwG6JuKgp2OYKxow=="
          filtered_message = Savon.filtered(Fixture.response(:authentication))
          filtered_message.should_not include(filtered_value)
          filtered_message.should include('***FILTERED***')
        end

        it "should not filter non-XML messages" do
          filtered_message = Savon.filtered('This is an information message.')
          filtered_message.should == 'This is an information message.'
        end
      end

      context "with multiple log filters set" do
        before(:each) do
          Savon.configure { |config| config.log_filter = ['logType','logTime'] }
        end

        it "should filter element values" do
          filtered_values = /Notes Log|2010-09-21T18:22:01|2010-09-21T18:22:07/
          filtered_message = Savon.filtered(Fixture.response(:list))

          filtered_message.should_not =~ filtered_values
          filtered_message.should include('<ns10:logTime>***FILTERED***</ns10:logTime>')
          filtered_message.should include('<ns10:logType>***FILTERED***</ns10:logType>')
          filtered_message.should include('<ns11:logTime>***FILTERED***</ns11:logTime>')
          filtered_message.should include('<ns11:logType>***FILTERED***</ns11:logType>')
        end

        it "should not filter non-XML messages" do
          filtered_message = Savon.filtered('This is an information message.')

          filtered_message.should == 'This is an information message.'
        end
      end

    end

    describe "log_level" do
      it "should default to :debug" do
        Savon.log_level.should == :debug
      end

      it "should set the log level to use" do
        Savon.configure { |config| config.log_level = :info }
        Savon.log_level.should == :info
      end
    end

    describe "raise_errors" do
      it "should default to true" do
        Savon.raise_errors?.should be_true
      end

      it "should not raise errors when disabled" do
        Savon.raise_errors = false
        Savon.raise_errors?.should be_false
      end
    end

    describe "soap_version" do
      it "should default to SOAP 1.1" do
        Savon.soap_version.should == 1
      end

      it "should return 2 if set to SOAP 1.2" do
        Savon.soap_version = 2
        Savon.soap_version.should == 2
      end

      it "should raise an ArgumentError in case of an invalid version" do
        lambda { Savon.soap_version = 3 }.should raise_error(ArgumentError)
      end
    end

    describe "strip_namespaces" do
      it "should default to true" do
        Savon.strip_namespaces?.should == true
      end

      it "should not strip namespaces when set to false" do
        Savon.strip_namespaces = false
        Savon.strip_namespaces?.should == false
      end
    end
  end

end
