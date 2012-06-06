require "spec_helper"

describe "Integration" do

  it "returns the result in a CDATA tag" do
    client = Savon.client("http://www.webservicex.net/stockquote.asmx?WSDL")
    response = client.request(:get_quote, :body => { :symbol => "AAPL" })

    cdata = response[:get_quote_response][:get_quote_result]
    result = Nori.parse(cdata)
    result[:stock_quotes][:stock][:symbol].should == "AAPL"
  end

  it "passes Strings as they are" do
    client = Savon.client("http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx?wsdl")
    response = client.request(:verify_email, :body => { :email => "soap@example.com", "LicenseKey" => "?" })

    response_text = response[:verify_email_response][:verify_email_result][:response_text]
    response_text.should == "Email Domain Not Found"
  end

end
