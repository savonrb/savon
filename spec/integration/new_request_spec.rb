 require "spec_helper"

describe "NewClient Integration" do

  subject(:client) {
    Savon.new_client(:wsdl => service_endpoint, :open_timeout => 10, :read_timeout => 10,
                     :raise_errors => false, :logger => Savon::NullLogger.new)
  }

  context "stockquote" do
    let(:service_endpoint) { "http://www.webservicex.net/stockquote.asmx?WSDL" }

    it "returns the result in a CDATA tag" do
      response = client.call(:get_quote, :message => { :symbol => "AAPL" })

      cdata = response.body[:get_quote_response][:get_quote_result]

      nori_options = { :convert_tags_to => lambda { |tag| tag.snakecase.to_sym } }
      result = Nori.new(nori_options).parse(cdata)

      result[:stock_quotes][:stock][:symbol].should == "AAPL"
    end
  end

  context "email" do
    let(:service_endpoint) { "http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx?wsdl" }

    it "passes Strings as they are" do
      response = client.call(:verify_email, :message => { :email => "soap@example.com", "LicenseKey" => "?" })

      response_text = response.body[:verify_email_response][:verify_email_result][:response_text]

      if response_text == "Current license key only allows so many checks"
        pending "API limit exceeded"
      else
        response_text.should == "Email Domain Not Found"
      end
    end
  end

  context "zip code" do
    let(:service_endpoint) { "http://www.thomas-bayer.com/axis2/services/BLZService?wsdl" }

    it "supports threads making requests simultaneously" do
      mutex = Mutex.new

      request_data = [70070010, 24050110, 20050550]
      threads_waiting = request_data.size

      threads = request_data.map do |blz|
        thread = Thread.new do
          response = client.call :get_bank, :message => { :blz => blz }
          Thread.current[:value] = response.body[:get_bank_response][:details]
          mutex.synchronize { threads_waiting -= 1 }
        end

        thread.abort_on_exception = true
        thread
      end

      sleep(1) until threads_waiting == 0

      threads.each(&:kill)
      values = threads.map { |thr| thr[:value] }.compact

      values.uniq.size.should == values.size
    end
  end

  context "redirectes" do
    it "follows 301 redirects"
    it "follows 302 redirects"
    it "follows 307 redirects"
  end

end
