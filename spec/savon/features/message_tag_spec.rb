require 'spec_helper'

describe Savon do

  it 'knows the message tag for :authentication' do
    message_tag = message_tag_for(:authentication, :authenticate)
    expect(message_tag).to eq(['http://v1_0.ws.auth.order.example.com/', 'authenticate'])
  end

  it 'knows the message tag for :taxcloud' do
    message_tag = message_tag_for(:taxcloud, :verify_address)
    expect(message_tag).to eq(['http://taxcloud.net', 'VerifyAddress'])
  end

  it 'knows the message tag for :team_software' do
    message_tag = message_tag_for(:team_software, :login)
    expect(message_tag).to eq(['http://tempuri.org/', 'Login'])
  end

  it 'knows the message tag for :interhome' do
    message_tag = message_tag_for(:interhome, :price_list)
    expect(message_tag).to eq(['http://www.interhome.com/webservice', 'PriceList'])
  end

  it 'knows the message tag for :betfair' do
    message_tag = message_tag_for(:betfair, :get_bet)
    expect(message_tag).to eq(['http://www.betfair.com/publicapi/v5/BFExchangeService/', 'getBet'])
  end

  it 'knows the message tag for :wasmuth' do
    message_tag = message_tag_for(:wasmuth, :get_st_tables)
    expect(message_tag).to eq(['http://ws.online.msw/', 'getStTables'])
  end

  def message_tag_for(fixture, operation_name)
    globals     = Savon::GlobalOptions.new(:log => false)
    wsdl        = Wasabi::Document.new Fixture.wsdl(fixture)
    operation   = Savon::Operation.create(operation_name, wsdl, globals)
    request_xml = operation.build.to_s

    nsid, local = extract_message_tag_from_request(request_xml)
    namespace   = extract_namespace_from_request(nsid, request_xml)

    [namespace, local]
  end

  def extract_message_tag_from_request(xml)
    match = xml.match(/<\w+?:Body><(.+?):(.+?)>/)
    [ match[1], match[2] ]
  end

  def extract_namespace_from_request(nsid, xml)
    xml.match(/xmlns:#{nsid}="(.+?)"/)[1]
  end

end
