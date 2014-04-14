 require "spec_helper"

describe "Stockquote example" do

  it "returns the result in a CDATA tag" do
    client = Savon.client(
      # The WSDL document provided by the service.
      :wsdl => "http://www.webservicex.net/stockquote.asmx?WSDL",

      # Lower timeouts so these specs don't take forever when the service is not available.
      :open_timeout => 10,
      :read_timeout => 10,

      # Disable logging for cleaner spec output.
      :log => false
    )

    response = call_and_fail_gracefully(client, :get_quote, :message => { :symbol => "AAPL" })

    cdata = response.body[:get_quote_response][:get_quote_result]

    nori_options = { :convert_tags_to => lambda { |tag| tag.snakecase.to_sym } }
    result = Nori.new(nori_options).parse(cdata)

    result[:stock_quotes][:stock][:symbol].should == "AAPL"
  end

end
