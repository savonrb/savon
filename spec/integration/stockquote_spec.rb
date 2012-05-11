require "spec_helper"

describe "webservicex/stockquote" do

  it "returns the result in a CDATA tag" do
    client = Savon.client("http://www.webservicex.net/stockquote.asmx?WSDL")
    response = client.request(:get_quote, :body => { :symbol => "AAPL" })

    cdata = response[:get_quote_response][:get_quote_result]
    result = Nori.parse(cdata)
    result[:stock_quotes][:stock][:symbol].should == "AAPL"
  end

end
