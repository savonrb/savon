# frozen_string_literal: true
require "spec_helper"
require "integration/support/server"

describe Savon::Message do

  before do
    @server = IntegrationServer.run
  end

  after do
    @server.stop
  end

  let(:client_config) {
    {
      :endpoint => @server.url(:repeat),
      :namespace => 'http://example.com',
      :log => false,

      :element_form_default => :qualified,
      :convert_request_keys_to => :camelcase,

      :convert_response_tags_to => nil
    }
  }

  let(:client) { Savon.client(client_config) }

  context "with a qualified message" do
    let(:message) {
      {
       :email_count => 3,
       :user_name   => 'josh',
       :order!      => [:user_name, :email_count]
      }
    }

    let(:converted_keys) {
      '<wsdl:UserName>josh</wsdl:UserName><wsdl:EmailCount>3</wsdl:EmailCount>'
    }
    it "converts request Hash keys for which there is not namespace" do
      response = client.call(:something, :message => message)
      expect(response.xml).to include(converted_keys)
    end
  end

  context 'use_wsa_headers' do
    let(:client_config) { super().merge(use_wsa_headers: true) }

    context 'headers' do
      [ 'wsa:Action', 'wsa:To', 'wsa:MessageID' ].each do |header|
        it "should include #{header} header" do
          response = client.call(:something, message: {})
          expect(response.xml).to include(header)
        end
      end
    end
  end

end
