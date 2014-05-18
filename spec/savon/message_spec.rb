require "spec_helper"
require "integration/support/server"

describe Savon::Message do

  before(:all) do
    @server = IntegrationServer.run
  end

  after(:all) do
    @server.stop
  end

  context "with a qualified message" do
    before(:each) do
      @client = Savon.client(
        :endpoint => @server.url(:repeat),
        :namespace => 'http://example.com',
        :log => false,

        :element_form_default => :qualified,
        :convert_request_keys_to => :camelcase,

        :convert_response_tags_to => nil
      )
    end

    it "converts request Hash keys for which there is not namespace" do
      message = {
       :email_count => 3,
       :user_name   => 'josh',
       :order!      => [:user_name, :email_count]
      }

      response = @client.call(:something, :message => message)

      expect(response.xml).to include('<wsdl:UserName>josh</wsdl:UserName><wsdl:EmailCount>3</wsdl:EmailCount>')
    end

    it "does not escape messages for Hash keys that end with a bang (!)" do
      message = {
        :escaped => '<![CDATA[ escaped data ]]>',
        :not_escaped! => '<![CDATA[ not escaped data ]]>',
      }

      response = @client.call(:something, :message => message)

      expect(response.xml).to include('<wsdl:Escaped>&lt;![CDATA[ escaped data ]]&gt;</wsdl:Escaped><wsdl:NotEscaped><![CDATA[ not escaped data ]]></wsdl:NotEscaped>')
    end
  end

end
