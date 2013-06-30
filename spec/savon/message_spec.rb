require "spec_helper"
require "integration/support/server"

describe Savon::Message do

  before do
    @server = IntegrationServer.run
  end

  after do
    @server.stop
  end

  context "with a qualified message" do
    it "converts request Hash keys for which there is not namespace" do
      client = Savon.client(
        :endpoint => @server.url(:repeat),
        :namespace => 'http://example.com',

        :element_form_default => :qualified,
        :convert_request_keys_to => :camelcase,

        :convert_response_tags_to => nil
      )

      message = {
       :email_count => 3,
       :user_name   => 'josh',
       :order!      => [:user_name, :email_count]
      }

      response = client.call(:something, :message => message)
      body = response.hash['Envelope']['Body']

      expect(response.xml).to include('<wsdl:UserName>josh</wsdl:UserName><wsdl:EmailCount>3</wsdl:EmailCount>')
    end
  end

end
