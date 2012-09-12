require "spec_helper"

describe Savon::SOAP::RequestBuilder do
  describe "#request" do
    def build_request_builder(operation)
      request_builder = Savon::SOAP::RequestBuilder.new(operation)

      request_builder.wsdl.document = Fixture.wsdl(:authentication)
      request_builder.soap = soap
      request_builder.http = http
      request_builder.config = config
      request_builder.wsse = wsse

      soap.stubs(:types).returns({})
      http.stubs(:headers).returns({})

      request_builder
    end

    let(:soap) { stub_everything('soap') }
    let(:http) { stub_everything('http') }
    let(:config) { stub_everything('config') }
    let(:wsse) { stub_everything('wsse') }
    let(:request_builder) { build_request_builder(:get_user) }

    before do
      Savon::SOAP::Request.stubs(:new).returns(stub_everything('request'))
    end

    describe "the configuration of dependencies" do
      it "sets the SOAP endpoint to the endpoint specified by the WSDL document" do
        endpoint = request_builder.wsdl.endpoint
        request_builder.wsdl.expects(:endpoint).returns(endpoint)
        soap.expects(:endpoint=).with(endpoint)

        request_builder.request
      end

      it "sets the SOAP element form default to the element form default specified by the WSDL document" do
        element_form_default = request_builder.wsdl.element_form_default
        request_builder.wsdl.expects(:element_form_default).returns(element_form_default)
        soap.expects(:element_form_default=).with(element_form_default)

        request_builder.request
      end

      it "sets the SOAP WSSE property to the WSSE property of the request builder" do
        soap.expects(:wsse=).with(wsse)

        request_builder.request
      end

      it "sets the SOAP namespace to the namespace specified by the WSDL document" do
        namespace = "http://v1_0.ws.auth.order.example.com/"
        soap.expects(:namespace=).with(namespace)

        request_builder.request
      end

      it "sets the SOAP namespace identifier to nil" do
        namespace_identifier = nil
        soap.expects(:namespace_identifier=).with(namespace_identifier)

        request_builder.request
      end

      it "sets the SOAP input to result in <getUser>" do
        soap_input = [nil, :getUser, {}]
        soap.expects(:input=).with(soap_input)

        request_builder.request
      end

      context "when the operation namespace is specified by the WSDL" do
        before do
          request_builder.wsdl.operations[:authenticate][:namespace_identifier] = "tns"
        end

        let(:request_builder) { build_request_builder(:authenticate) }

        it "sets the SOAP namespace to the operation's namespace" do
          namespace = "http://v1_0.ws.auth.order.example.com/"
          soap.expects(:namespace=).with(namespace)

          request_builder.request
        end

        it "sets the SOAP namespace identifier to the operation's namespace identifier" do
          namespace_identifier = :tns
          soap.expects(:namespace_identifier=).with(namespace_identifier)

          request_builder.request
        end

        it "sets the SOAP input to include the namespace identifier" do
          soap_input = [:tns, :authenticate, {}]
          soap.expects(:input=).with(soap_input)

          request_builder.request
        end
      end

      context "when the operation is a string" do
        let(:request_builder) { build_request_builder("get_user") }
        it "should set the SOAP input tag to <get_user>" do
          soap_input = [nil, :get_user, {}]
          soap.expects(:input=).with(soap_input)

          request_builder.request
        end
      end

      context "when attributes are specified" do
        it "should add the attributes to the SOAP input" do
          request_builder.attributes = { :active => true }
          soap_input = [nil, :getUser, { :active => true }]
          soap.expects(:input=).with(soap_input)

          request_builder.request
        end
      end

      context "when a SOAP action is specified" do
        it "sets the SOAPAction header" do
          request_builder.soap_action = :test_action
          request_builder.request

          http.headers["SOAPAction"].should == %{"test_action"}
        end
      end

      context "when the namespace identifier is specified" do
        before do
          @namespace_identifier = :v1
          request_builder.namespace_identifier = @namespace_identifier
        end

        it "should set the SOAP namespace identifier to the specified identifier" do
          soap.expects(:namespace_identifier=).with(@namespace_identifier)

          request_builder.request
        end

        it "should set the SOAP input to include the specified identifier" do
          soap_input = [@namespace_identifier, :getUser, {}]
          soap.expects(:input=).with(soap_input)

          request_builder.request
        end

        it "should set the SOAP namespace to the one matched by the specified identifier" do
          namespace = "http://v1_0.ws.auth.order.example.com/"
          soap.expects(:namespace=).with(namespace)

          request_builder.request
        end
      end

      it "adds the WSDL document namespaces to the SOAP::XML object" do
        request_builder.wsdl.type_namespaces.each do |path, uri|
          soap.expects(:use_namespace).with(path, uri)
        end

        request_builder.request
      end

      it "adds the WSDL document types to the SOAP::XML object" do
        request_builder.request

        request_builder.wsdl.type_definitions do |path, type|
          soap.types.has_key?(path).should be_true
          soap.types[path].should == type
        end
      end
    end

    context "with a post-configuration block given" do
      it "executes the block" do
        executed = false
        blk = lambda { executed = true }

        request_builder.request(&blk)
        executed.should == true
      end

      it "executes the block post-configuration" do
        request_builder.namespace_identifier = :conf
        blk = lambda { |rb| rb.soap.namespace_identifier = :blk }

        conf_sequence = sequence('conf_sequence')
        soap.expects(:namespace_identifier=).with(:conf).in_sequence(conf_sequence)
        soap.expects(:namespace_identifier=).with(:blk).in_sequence(conf_sequence)

        request_builder.request(&blk)
      end

      context "when the block has an argument" do
        it "yields self to the block" do
          request_builder = self.request_builder
          blk = lambda { |rb_given| rb_given.should == request_builder }

          request_builder.request(&blk)
        end
      end
    end
  end
end
