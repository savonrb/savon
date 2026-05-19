# frozen_string_literal: true

require "spec_helper"
require "integration/support/server"

RSpec.describe Savon::Message do
  before do
    @server = IntegrationServer.run
  end

  after do
    @server.stop
  end

  let(:client_config) do
    {
      :endpoint                 => @server.url(:repeat),
      :namespace                => 'http://example.com',
      :log                      => false,

      :element_form_default     => :qualified,
      :convert_request_keys_to  => :camelcase,

      :convert_response_tags_to => nil
    }
  end

  let(:client) { Savon.client(client_config) }

  context "with a qualified message" do
    let(:message) do
      {
        :email_count => 3,
        :user_name   => 'josh',
        :order!      => %i[user_name email_count]
      }
    end

    let(:converted_keys) do
      '<wsdl:UserName>josh</wsdl:UserName><wsdl:EmailCount>3</wsdl:EmailCount>'
    end

    it "converts request Hash keys for which there is not namespace" do
      response = client.call(:something, :message => message)
      expect(response.xml).to include(converted_keys)
    end
  end

  context 'use_wsa_headers' do
    let(:client_config) { super().merge(use_wsa_headers: true) }

    context 'headers' do
      ['wsa:Action', 'wsa:To', 'wsa:MessageID'].each do |header|
        it "includes #{header} header" do
          response = client.call(:something, message: {})
          expect(response.xml).to include(header)
        end
      end
    end
  end
end
