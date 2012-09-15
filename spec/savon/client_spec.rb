require "spec_helper"

describe Savon::Client do
  let(:client) { Savon::Client.new { wsdl.document = Endpoint.wsdl } }

  describe ".new" do
    context "with a String" do
      it "should set the WSDL document" do
        wsdl = "http://example.com/UserService?wsdl"
        client = Savon::Client.new(wsdl)
        client.wsdl.instance_variable_get("@document").should == wsdl
      end
    end

    context "with a block expecting one argument" do
      it "should yield the WSDL object" do
        Savon::Client.new { |wsdl| wsdl.should be_a(Wasabi::Document) }
      end
    end

    context "with a block expecting two arguments" do
      it "should yield the WSDL and HTTP objects" do
        Savon::Client.new do |wsdl, http|
          wsdl.should be_an(Wasabi::Document)
          http.should be_an(HTTPI::Request)
        end
      end
    end

    context "with a block expecting three arguments" do
      it "should yield the WSDL, HTTP and WSSE objects" do
        Savon::Client.new do |wsdl, http, wsse|
          wsdl.should be_an(Wasabi::Document)
          http.should be_an(HTTPI::Request)
          wsse.should be_an(Akami::WSSE)
        end
      end
    end

    context "with a block expecting no arguments" do
      it "should let you access the WSDL object" do
        Savon::Client.new { wsdl.should be_a(Wasabi::Document) }
      end

      it "should let you access the HTTP object" do
        Savon::Client.new { http.should be_an(HTTPI::Request) }
      end

      it "should let you access the WSSE object" do
        Savon::Client.new { wsse.should be_a(Akami::WSSE) }
      end
    end
  end

  describe "#wsdl" do
    it "should return the Savon::Wasabi::Document" do
      client.wsdl.should be_a(Wasabi::Document)
    end
  end

  describe "#http" do
    it "should return the HTTPI::Request" do
      client.http.should be_an(HTTPI::Request)
    end
  end

  describe "#wsse" do
    it "should return the Akami::WSSE object" do
      client.wsse.should be_a(Akami::WSSE)
    end
  end

  describe "#request" do
    let(:request_builder) { stub_everything('request_builder') }
    let(:response) { mock('response') }

    before do
      HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:authentication)))
      HTTPI.stubs(:post).returns(new_response)

      Savon::SOAP::RequestBuilder.stubs(:new).returns(request_builder)
      request_builder.stubs(:request).returns(stub(:response => response))
      response.stubs(:http).returns(new_response)
    end

    context "without any arguments" do
      it "should raise an ArgumentError" do
        lambda { client.request }.should raise_error(ArgumentError)
      end
    end

    describe "setting dependencies of the request builder" do
      it "sets the wsdl property with the client's WSDL document" do
        request_builder.expects(:wsdl=).with(client.wsdl)
        client.request(:get_user)
      end

      it "sets the http property with an HTTPI::Request object" do
        request_builder.expects(:http=).with { |http| http.is_a?(HTTPI::Request) }
        client.request(:get_user)
      end

      it "sets the wsse property with an Akami:WSSE object" do
        request_builder.expects(:wsse=).with { |wsse| wsse.is_a?(Akami::WSSE) }
        client.request(:get_user)
      end

      it "sets the config property with a Savon::Config object" do
        request_builder.expects(:config=).with { |config| config.is_a?(Savon::Config) }
        client.request(:get_user)
      end
    end

    context "with a single argument" do
      it "sets the operation of the request builder to the argument" do
        expect_request_builder_to_receive(:get_user)
        client.request(:get_user)
      end
    end

    context "with a Symbol and a Hash" do
      it "uses the hash to set attributes of the request builder" do
        expect_request_builder_to_receive(:get_user, :attributes => { :active => true })
        client.request(:get_user, :active => true)
      end

      it "uses the :soap_action key of the hash to set the SOAP action of the request builder" do
        expect_request_builder_to_receive(:get_user, :soap_action => :test_action)
        client.request(:get_user, :soap_action => :test_action)
      end

      it "uses the :body key of the hash to set the SOAP body of the request builder" do
        expect_request_builder_to_receive(:get_user, :body => { :foo => "bar" })
        client.request(:get_user, :body => { :foo => "bar" })
      end
    end

    context "with two Symbols" do
      it "uses the first symbol to set the namespace and the second symbol to set the operation of the request builder" do
        expect_request_builder_to_receive(:get_user, :namespace_identifier => :v1)
        client.request(:v1, :get_user)
      end

      it "should not set the target namespace if soap.namespace was set to nil in the post-configuration block" do
        Savon::SOAP::RequestBuilder.unstub(:new)

        namespace = 'xmlns:v1="http://v1_0.ws.auth.order.example.com/"'
        HTTPI::Request.any_instance.expects(:body=).with { |value| !value.include?(namespace) }

        client.request(:v1, :get_user) { soap.namespace = nil }
      end
    end

    context "with two Symbols and a Hash" do
      it "uses the first symbol to set the namespace and the second symbol to set the operation of the request builder" do
        expect_request_builder_to_receive(:get_user, :namespace_identifier => :wsdl)
        client.request(:wsdl, :get_user)
      end

      it "should use the hash to set the attributes of the request builder" do
        expect_request_builder_to_receive(:get_user, :namespace_identifier => :wsdl, :attributes => { :active => true })
        client.request(:wsdl, :get_user, :active => true)
      end

      it "should use the :soap_action key of the hash to set the SOAP action of the request builder" do
        expect_request_builder_to_receive(:get_user, :namespace_identifier => :wsdl, :soap_action => :test_action)
        client.request(:wsdl, :get_user, :soap_action => :test_action)
      end

      it "should use the :body key of the hash to set the SOAP body of the request builder" do
        expect_request_builder_to_receive(:get_user, :namespace_identifier => :wsdl, :body => { :foo => "bar" })
        client.request(:wsdl, :get_user, :body => { :foo => "bar" })
      end
    end

    context "with a block" do
      before do
        Savon::SOAP::RequestBuilder.unstub(:new)
      end

      it "passes the block to the request builder" do
        # this is painful. it would be trivial to test in > Ruby 1.9, but this is
        # the only way I know how in < 1.9.
        dummy = Object.new
        dummy.instance_eval do
          class << self; attr_accessor :request_builder, :block_given; end
          def request
            self.block_given = block_given?
            request_builder.request
          end

          def method_missing(_, *args)
          end
        end

        dummy.request_builder = request_builder
        Savon::SOAP::RequestBuilder.stubs(:new).returns(dummy)

        blk = lambda {}
        client.request(:authenticate, &blk)

        dummy.block_given.should == true
      end

      it "executes the block in the context of the request builder" do
        Savon::SOAP::RequestBuilder.class_eval do
          def who
            self
          end
        end

        client.request(:authenticate) { who.should be_a Savon::SOAP::RequestBuilder }
      end

      context "with a block expecting one argument" do
        it "should yield the SOAP object" do
          client.request(:authenticate) { |soap| soap.should be_a Savon::SOAP::XML }
        end
      end

      context "with a block expecting two arguments" do
        it "should yield the SOAP and WSDL objects" do
          client.request(:authenticate) do |soap, wsdl|
            soap.should be_a(Savon::SOAP::XML)
            wsdl.should be_an(Wasabi::Document)
          end
        end
      end

      context "with a block expecting three arguments" do
        it "should yield the SOAP, WSDL and HTTP objects" do
          client.request(:authenticate) do |soap, wsdl, http|
            soap.should be_a(Savon::SOAP::XML)
            wsdl.should be_an(Wasabi::Document)
            http.should be_an(HTTPI::Request)
          end
        end
      end

      context "with a block expecting four arguments" do
        it "should yield the SOAP, WSDL, HTTP and WSSE objects" do
          client.request(:authenticate) do |soap, wsdl, http, wsse|
            soap.should be_a(Savon::SOAP::XML)
            wsdl.should be_a(Wasabi::Document)
            http.should be_an(HTTPI::Request)
            wsse.should be_a(Akami::WSSE)
          end
        end
      end

      context "with a block expecting no arguments" do
        it "should let you access the SOAP object" do
          client.request(:authenticate) { soap.should be_a(Savon::SOAP::XML) }
        end

        it "should let you access the HTTP object" do
          client.request(:authenticate) { http.should be_an(HTTPI::Request) }
        end

        it "should let you access the WSSE object" do
          client.request(:authenticate) { wsse.should be_a(Akami::WSSE) }
        end

        it "should let you access the WSDL object" do
          client.request(:authenticate) { wsdl.should be_a(Wasabi::Document) }
        end
      end
    end

    it "should not set the Cookie header for the next request" do
      client.request :authenticate
      client.http.headers["Cookie"].should be_nil
    end
  end

  context "#request with a Set-Cookie response header" do
    before do
      HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:authentication)))
      HTTPI.stubs(:post).returns(new_response(:headers => { "Set-Cookie" => "some-cookie=choc-chip; Path=/; HttpOnly" }))
    end

    it "sets the cookies for the next request" do
      client.http.expects(:set_cookies).with(kind_of(HTTPI::Response))
      client.request :authenticate
    end
  end

  context "with a remote WSDL document" do
    let(:client) { Savon::Client.new { wsdl.document = Endpoint.wsdl } }
    before { HTTPI.expects(:get).returns(new_response(:body => Fixture.wsdl(:authentication))) }

    it "adds a SOAPAction header containing the SOAP action name" do
      HTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "should execute SOAP requests and return the response" do
      HTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(Savon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "with a local WSDL document" do
    let(:client) { Savon::Client.new { wsdl.document = "spec/fixtures/wsdl/authentication.xml" } }

    before { HTTPI.expects(:get).never }

    it "adds a SOAPAction header containing the SOAP action name" do
      HTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "should execute SOAP requests and return the response" do
      HTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(Savon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "when the WSDL specifies multiple namespaces" do
    before do
      HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:multiple_namespaces)))
      HTTPI.stubs(:post).returns(new_response)
    end

    it "qualifies each element with the appropriate namespace" do
      HTTPI::Request.any_instance.expects(:body=).with do |value|
        xml = Nokogiri::XML(value)

        title = xml.at_xpath(
          ".//actions:Save/actions:article/article:Title/text()",
          "article" => "http://example.com/article",
          "actions" => "http://example.com/actions").to_s
        author = xml.at_xpath(
          ".//actions:Save/actions:article/article:Author/text()",
          "article" => "http://example.com/article",
          "actions" => "http://example.com/actions").to_s

        title == "Hamlet" && author == "Shakespeare"
      end

      client.request :save do
        soap.body = { :article => { "Title" => "Hamlet", "Author" => "Shakespeare" } }
      end
    end

    it "still sends nil as xsi:nil as in the non-namespaced case" do
      HTTPI::Request.any_instance.expects(:body=).with do |value|
        xml = Nokogiri::XML(value)

        attribute = xml.at_xpath(".//article:Title/@xsi:nil",
          "xsi" => "http://www.w3.org/2001/XMLSchema-instance",
          "article" => "http://example.com/article").to_s

        attribute == "true"
      end

      client.request(:save) { soap.body = { :article => { "Title" => nil } } }
    end

    it "translates between symbol :save and string 'Save'" do
      HTTPI::Request.any_instance.expects(:body=).with do |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save", "actions" => "http://example.com/actions")
      end

      client.request :save do
        soap.body = { :article => { :title => "Hamlet", :author => "Shakespeare" } }
      end
    end

    it "qualifies Save with the appropriate namespace" do
      HTTPI::Request.any_instance.expects(:body=).with do |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save", "actions" => "http://example.com/actions")
      end

      client.request "Save" do
        soap.body = { :article => { :title => "Hamlet", :author => "Shakespeare" } }
      end
    end
  end

  context "when the WSDL has a lowerCamel name" do
    before do
      HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:lower_camel)))
      HTTPI.stubs(:post).returns(new_response)
    end

    it "appends namespace when name is specified explicitly" do
      HTTPI::Request.any_instance.expects(:body=).with do |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save/actions:lowerCamel", "actions" => "http://example.com/actions")
      end

      client.request("Save") { soap.body = { 'lowerCamel' => 'theValue' } }
    end

    it "still appends namespace when converting from symbol" do
      HTTPI::Request.any_instance.expects(:body=).with do |value|
        xml = Nokogiri::XML(value)
        !!xml.at_xpath(".//actions:Save/actions:lowerCamel", "actions" => "http://example.com/actions")
      end

      client.request("Save") { soap.body = { :lower_camel => 'theValue' } }
    end
  end

  context "with multiple types" do
    before do
      HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:multiple_types)))
      HTTPI.stubs(:post).returns(new_response)
    end

    it "does not blow up" do
      HTTPI::Request.any_instance.expects(:body=).with { |value| value.include?("Save") }
      client.request(:save) { soap.body = {} }
    end
  end

  context "with an Array of namespaced items" do
    context "with a single namespace" do
      let(:client) { Savon::Client.new { wsdl.document = "spec/fixtures/wsdl/taxcloud.xml" } }

      before do
        HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:taxcloud)))
        HTTPI.stubs(:post).returns(new_response)
      end

      it "should namespaces each Array item as expected" do
        HTTPI::Request.any_instance.expects(:body=).with do |value|
          xml = Nokogiri::XML(value)
          !!xml.at_xpath(".//tc:cartItems/tc:CartItem/tc:ItemID", { "tc" => "http://taxcloud.net" })
        end

        address = { "Address1" => "888 6th Ave", "Address2" => nil, "City" => "New York", "State" => "NY", "Zip5" => "10001", "Zip4" => nil }
        cart_item = { "Index" => 0, "ItemID" => "SKU-TEST", "TIC" => "00000", "Price" => 50.0, "Qty" => 1 }

        client.request :lookup, :body => {
          "customerID"  => 123,
          "cartID"      => 456,
          "cartItems"   => { "CartItem" => [cart_item] },
          "origin"      => address,
          "destination" => address
        }
      end
    end

    context "with multiple namespaces" do
      let(:client) { Savon::Client.new { wsdl.document = "spec/fixtures/wsdl/multiple_namespaces.xml" } }

      before do
        HTTPI.stubs(:get).returns(new_response(:body => Fixture.wsdl(:multiple_namespaces)))
        HTTPI.stubs(:post).returns(new_response)
      end

      it "should namespace each Array item as expected" do
        HTTPI::Request.any_instance.expects(:body=).with do |value|
          xml = Nokogiri::XML(value)
          namespaces = { "actions" => "http://example.com/actions", "article" => "http://example.com/article" }
          !!xml.at_xpath(".//actions:Lookup/actions:articles/article:Article/article:Author", namespaces)
        end

        article = { "Author" => "John Smith", "Title" => "Modern SOAP" }
        client.request :lookup, :body => {
          "articles" => { "Article" => [article] }
        }
      end
    end

  end

  context "without a WSDL document" do
    let(:client) do
      Savon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { HTTPI.expects(:get).never }

    it "raise an ArgumentError when trying to access the WSDL" do
      lambda { client.wsdl.soap_actions }.should raise_error(ArgumentError, /Wasabi/)
    end

    it "adds a SOAPAction header containing the SOAP action name" do
      HTTPI.stubs(:post).returns(new_response)

      client.request :authenticate do
        http.headers["SOAPAction"].should == %{"authenticate"}
      end
    end

    it "should execute SOAP requests and return the response" do
      HTTPI.expects(:post).returns(new_response)
      response = client.request(:authenticate)

      response.should be_a(Savon::SOAP::Response)
      response.to_xml.should == Fixture.response(:authentication)
    end
  end

  context "when encountering a SOAP fault" do
    let(:client) do
      Savon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { HTTPI::expects(:post).returns(new_response(:code => 500, :body => Fixture.response(:soap_fault))) }

    it "should raise a Savon::SOAP::Fault" do
      lambda { client.request :authenticate }.should raise_error(Savon::SOAP::Fault)
    end
  end

  context "when encountering an HTTP error" do
    let(:client) do
      Savon::Client.new do
        wsdl.endpoint = Endpoint.soap
        wsdl.namespace = "http://v1_0.ws.auth.order.example.com/"
      end
    end

    before { HTTPI::expects(:post).returns(new_response(:code => 500)) }

    it "should raise a Savon::HTTP::Error" do
      lambda { client.request :authenticate }.should raise_error(Savon::HTTP::Error)
    end
  end

  def new_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    HTTPI::Response.new response[:code], response[:headers], response[:body]
  end

  def expect_request_builder_to_receive(operation, options = {})
    Savon::SOAP::RequestBuilder.expects(:new).with(operation, options).returns(request_builder)
  end

end
