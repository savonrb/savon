require "spec_helper"

describe Savon::Model do

  let(:model) do
    Class.new { extend Savon::Model }
  end

  describe ".client" do
    it "memoizes the Savon::Client" do
      model.client.should equal(model.client)
    end
  end

  describe ".endpoint" do
    it "sets the SOAP endpoint" do
      model.endpoint "http://example.com"
      model.client.wsdl.endpoint.should == "http://example.com"
    end
  end

  describe ".namespace" do
    it "sets the target namespace" do
      model.namespace "http://v1.example.com"
      model.client.wsdl.namespace.should == "http://v1.example.com"
    end
  end

  describe ".document" do
    it "sets the WSDL document" do
      model.document "http://example.com/?wsdl"
      model.client.wsdl.document.should == "http://example.com/?wsdl"
    end
  end

  describe ".headers" do
    it "sets the HTTP headers" do
      model.headers("Accept-Charset" => "utf-8")
      model.client.http.headers.should == { "Accept-Charset" => "utf-8" }
    end
  end

  describe ".basic_auth" do
    it "sets HTTP Basic auth credentials" do
      model.basic_auth "login", "password"
      model.client.http.auth.basic.should == ["login", "password"]
    end
  end

  describe ".wsse_auth" do
    it "sets WSSE auth credentials" do
      model.wsse_auth "login", "password", :digest

      model.client.wsse.username.should == "login"
      model.client.wsse.password.should == "password"
      model.client.wsse.should be_digest
    end
  end

  describe ".actions" do
    before(:all) do
      model.actions :get_user, "GetAllUsers"
    end

    it "defines class methods each action" do
      model.should respond_to(:get_user, :get_all_users)
    end

    it "defines instance methods each action" do
      model.new.should respond_to(:get_user, :get_all_users)
    end

    context "(class-level)" do
      it "executes SOAP requests with a given body" do
        model.client.expects(:request).with(:wsdl, :get_user, :body => { :id => 1 })
        model.get_user :id => 1
      end

      it "accepts and passes Strings for action names" do
        model.client.expects(:request).with(:wsdl, "GetAllUsers", :body => { :id => 1 })
        model.get_all_users :id => 1
      end
    end

    context "(instance-level)" do
      it "delegates to the corresponding class method" do
        model.expects(:get_all_users).with(:active => true)
        model.new.get_all_users :active => true
      end
    end
  end

  describe "#client" do
    it "returns the class-level Savon::Client" do
      model.new.client.should == model.client
    end
  end

  describe "overwriting action methods" do
    context "(class-level)" do
      let(:supermodel) do
        supermodel = model.dup
        supermodel.actions :get_user

        def supermodel.get_user(body = nil, &block)
          p "super"
          super
        end

        supermodel
      end

      it "works" do
        supermodel.client.expects(:request).with(:wsdl, :get_user, :body => { :id => 1 })
        supermodel.expects(:p).with("super")  # stupid, but works

        supermodel.get_user :id => 1
      end
    end

    context "(instance-level)" do
      let(:supermodel) do
        supermodel = model.dup
        supermodel.actions :get_user
        supermodel = supermodel.new

        def supermodel.get_user(body = nil, &block)
          p "super"
          super
        end

        supermodel
      end

      it "works" do
        supermodel.client.expects(:request).with(:wsdl, :get_user, :body => { :id => 1 })
        supermodel.expects(:p).with("super")  # stupid, but works

        supermodel.get_user :id => 1
      end
    end
  end

end
