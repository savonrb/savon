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

  it "supports threads making requests simultaneously" do
    client = Savon::Client.new do
        wsdl.document = "http://www.thomas-bayer.com/axis2/services/BLZService?wsdl"
    end

    mutex = Mutex.new

    request_data = [70070010, 24050110, 20050550]
    threads_waiting = request_data.size

    threads = request_data.map do |blz|
      Thread.new do
        response = client.request :get_bank, :body => { :blz => blz }
        Thread.current[:value] = response.to_hash[:get_bank_response][:details]
        mutex.synchronize { threads_waiting -= 1 }
      end
    end

    sleep(1) until threads_waiting == 0

    threads.each &:kill
    values = threads.map { |thr| thr[:value] }.compact

    values.uniq.size.should == values.size
  end
end
