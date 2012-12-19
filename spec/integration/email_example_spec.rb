 require "spec_helper"

describe "Email example" do

  subject(:client) {
    Savon.client(:wsdl => service_endpoint, :open_timeout => 10, :read_timeout => 10,
                 :raise_errors => false, :log => false)
  }

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
