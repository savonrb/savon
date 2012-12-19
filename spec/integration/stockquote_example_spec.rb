 require "spec_helper"

describe "Stockquote example" do

  subject(:client) {
    Savon.client(:wsdl => service_endpoint, :open_timeout => 10, :read_timeout => 10,
                 :raise_errors => false, :log => false)
  }

  let(:service_endpoint) { "http://www.webservicex.net/stockquote.asmx?WSDL" }

  it "returns the result in a CDATA tag" do
    response = client.call(:get_quote, :message => { :symbol => "AAPL" })

    cdata = response.body[:get_quote_response][:get_quote_result]

    nori_options = { :convert_tags_to => lambda { |tag| tag.snakecase.to_sym } }
    result = Nori.new(nori_options).parse(cdata)

    result[:stock_quotes][:stock][:symbol].should == "AAPL"
  end

end
