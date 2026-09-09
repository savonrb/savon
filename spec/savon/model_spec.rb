# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"

RSpec.describe Savon::Model do
  describe ".client" do
    it "returns the memoized client" do
      model = Class.new do
        extend Savon::Model
        client wsdl: Fixture.wsdl(:authentication)
      end

      expect(model.client).to be_a(Savon::Client)
      expect(model.client).to equal(model.client)
    end

    it "raises if the client was not initialized properly" do
      model = Class.new { extend Savon::Model }

      expect { model.client }
        .to raise_error(Savon::InitializationError, /^Expected the model to be initialized/)
    end
  end

  describe ".global" do
    it "sets global options" do
      model = Class.new do
        extend Savon::Model

        client wsdl: Fixture.wsdl(:authentication)

        global :soap_version, 2
        global :open_timeout, 71
        global :wsse_auth, "luke", "secret", :digest
      end

      expect(model.client.globals[:soap_version]).to eq(2)
      expect(model.client.globals[:open_timeout]).to eq(71)
      expect(model.client.globals[:wsse_auth]).to eq(["luke", "secret", :digest])
    end
  end

  describe ".operations" do
    %i[client Client CLIENT global setup operations all_operations
       define_class_operation define_instance_operation operation_method_name
       class_operation_module instance_operation_module raise_initialization_error!].each do |operation|
      it "rejects the reserved operation name #{operation}" do
        model = Class.new { extend Savon::Model }

        expect { model.operations(operation) }
          .to raise_error(ArgumentError, /reserved Savon::Model method/)
      end
    end

    it "validates all names before defining any operations" do
      model = Class.new { extend Savon::Model }

      expect { model.operations(:authenticate, :client) }.to raise_error(ArgumentError)
      expect(model).not_to respond_to(:authenticate)
      expect(model.new).not_to respond_to(:authenticate)
    end

    it "allows operations to be registered more than once" do
      model = Class.new { extend Savon::Model }

      2.times do
        model.operations(:authenticate)
      end

      expect(model).to respond_to(:authenticate)
      expect(model.new).to respond_to(:authenticate)
    end

    it "defines class methods for each operation" do
      model = Class.new do
        extend Savon::Model

        client wsdl: Fixture.wsdl(:authentication)
        operations :authenticate
      end

      expect(model).to respond_to(:authenticate)
    end

    it "executes class-level SOAP operations" do
      repeat_url = integration_server.url(:repeat)

      model = Class.new do
        extend Savon::Model

        client endpoint: repeat_url, namespace: "http://v1.example.com"
        global :log, false

        operations :authenticate
      end

      response = model.authenticate(xml: Fixture.response(:authentication))
      expect(response.body[:authenticate_response][:return]).to include(:authentication_value)
    end

    it "defines instance methods for each operation" do
      model = Class.new do
        extend Savon::Model

        client wsdl: Fixture.wsdl(:authentication)
        operations :authenticate
      end

      model_instance = model.new
      expect(model_instance).to respond_to(:authenticate)
    end

    it "executes instance-level SOAP operations" do
      repeat_url = integration_server.url(:repeat)

      model = Class.new do
        extend Savon::Model

        client endpoint: repeat_url, namespace: "http://v1.example.com"
        global :log, false

        operations :authenticate
      end

      model_instance = model.new
      response = model_instance.authenticate(xml: Fixture.response(:authentication))
      expect(response.body[:authenticate_response][:return]).to include(:authentication_value)
    end

    it "generates class methods with source location pointing to model.rb" do
      model = Class.new do
        extend Savon::Model
        client wsdl: Fixture.wsdl(:authentication)
        operations :authenticate
      end

      file, line = model.method(:authenticate).source_location
      expect(file).to end_with("savon/model.rb")
      expect(File.readlines(file)[line - 1]).to include("define_method")
    end

    it "generates instance methods with source location pointing to model.rb" do
      model = Class.new do
        extend Savon::Model
        client wsdl: Fixture.wsdl(:authentication)
        operations :authenticate
      end

      file, line = model.instance_method(:authenticate).source_location
      expect(file).to end_with("savon/model.rb")
      expect(File.readlines(file)[line - 1]).to include("define_method")
    end
  end

  it "allows to overwrite class operations" do
    repeat_url = integration_server.url(:repeat)

    model = Class.new do
      extend Savon::Model
      client endpoint: repeat_url, namespace: "http://v1.example.com"
    end

    supermodel = model.dup
    supermodel.operations :authenticate

    def supermodel.authenticate(locals = {})
      p "super"
      super
    end

    supermodel.client.expects(:call).with(:authenticate, message: { username: "luke", password: "secret" })
    supermodel.expects(:p).with("super")  # stupid, but works

    supermodel.authenticate(message: { username: "luke", password: "secret" })
  end

  it "allows to overwrite instance operations" do
    repeat_url = integration_server.url(:repeat)

    model = Class.new do
      extend Savon::Model
      client endpoint: repeat_url, namespace: "http://v1.example.com"
    end

    supermodel = model.dup
    supermodel.operations :authenticate
    supermodel = supermodel.new

    def supermodel.authenticate(lcoals = {})
      p "super"
      super
    end

    supermodel.client.expects(:call).with(:authenticate, message: { username: "luke", password: "secret" })
    supermodel.expects(:p).with("super")  # stupid, but works

    supermodel.authenticate(message: { username: "luke", password: "secret" })
  end

  describe ".all_operations" do
    it "rejects a WSDL operation named client without overwriting the client accessor" do
      wsdl = <<~XML
        <?xml version="1.0"?>
        <wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                          xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                          name="Service" targetNamespace="urn:test">
          <wsdl:binding name="Binding" type="wsdl:Port">
            <soap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
            <wsdl:operation name="client">
              <soap:operation soapAction="urn:test#client"/>
            </wsdl:operation>
          </wsdl:binding>
        </wsdl:definitions>
      XML
      model = Class.new do
        extend Savon::Model
        client wsdl: wsdl
      end
      client = model.client

      expect { model.all_operations }.to raise_error(ArgumentError, /reserved Savon::Model method/)
      expect(model.client).to equal(client)
      expect(model.new.client).to equal(client)
      model.global :soap_version, 2
      expect(client.globals[:soap_version]).to eq(2)
      client.expects(:call).with(:client, message: { value: "test" }).returns(:response)
      expect(model.client.call(:client, message: { value: "test" })).to eq(:response)
    end

    it "calls operations with all available client operations" do
      model = Class.new do
        extend Savon::Model

        client wsdl: Fixture.wsdl(:taxcloud)
        all_operations
      end

      %i[verify_address
         lookup_for_date
         lookup
         authorized
         authorized_with_capture
         captured
         returned
         get_tic_groups
         get_ti_cs
         get_ti_cs_by_group
         add_exempt_certificate
         delete_exempt_certificate
         get_exempt_certificates].each do |method|
        expect(model).to respond_to(method)
      end
    end

    it "treats WSDL operation names as data when generating model methods" do
      evidence = File.expand_path("../../pwned_savon_model_spec", __dir__)
      File.delete(evidence) if File.exist?(evidence)

      malicious_wsdl = <<~XML
        <?xml version="1.0"?>
        <wsdl:definitions xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
                          xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
                          name="EvilService" targetNamespace="urn:evil">
          <wsdl:binding name="EvilBinding" type="wsdl:EvilPort">
            <soap:binding style="rpc" transport="http://schemas.xmlsoap.org/soap/http"/>
            <wsdl:operation name="foo&#10;end&#10;`echo exploited &gt; pwned_savon_model_spec 2&gt;&amp;1`&#10;def x">
              <soap:operation soapAction="urn:evil#foo"/>
            </wsdl:operation>
          </wsdl:binding>
        </wsdl:definitions>
      XML

      model = Class.new do
        extend Savon::Model
        client wsdl: malicious_wsdl
      end

      expect { model.all_operations }.not_to change { File.exist?(evidence) }.from(false)
    ensure
      File.delete(evidence) if evidence && File.exist?(evidence)
    end
  end
end
