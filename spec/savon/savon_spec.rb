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

      context "when instructed to filter" do
        before do
          Savon.log = true
        end

        context "and no log filter set" do
          it "should not filter the message" do
            Savon.logger.expects(Savon.log_level).with(Fixture.response(:authentication))
            Savon.log(Fixture.response(:authentication), :filter)
          end
        end

        context "and multiple log filters" do
          before do
            Savon.configure { |config| config.log_filter = ["logType", "logTime"] }
          end

          it "should filter element values" do
            filtered_values = /Notes Log|2010-09-21T18:22:01|2010-09-21T18:22:07/

            Savon.logger.expects(Savon.log_level).with do |msg|
              msg !~ filtered_values &&
              msg.include?('<ns10:logTime>***FILTERED***</ns10:logTime>') &&
              msg.include?('<ns10:logType>***FILTERED***</ns10:logType>') &&
              msg.include?('<ns11:logTime>***FILTERED***</ns11:logTime>') &&
              msg.include?('<ns11:logType>***FILTERED***</ns11:logType>')
            end

            Savon.log(Fixture.response(:list), :xml)
          end
        end

        context "pretty_xml_logs is set" do
          it "returns formatted xml with indentation" do
            Savon.configure { |config| config.pretty_xml_logs = true }
            Savon.logger.expects(Savon.log_level).with <<-EOF
<?xml version="1.0"?>
<hello>
  <world>Bob</world>
</hello>
EOF
            Savon.log("<?xml version=\"1.0\"?><hello><world>Bob</world></hello>", :xml)
          end
        end
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
  end

end
