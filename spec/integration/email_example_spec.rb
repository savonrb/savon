 require "spec_helper"

describe "Email example" do

  it "passes Strings as they are" do
    client = Savon.client(
      # The WSDL document provided by the service.
      :wsdl => "http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx?wsdl",

      # Lower timeouts so these specs don't take forever when the service is not available.
      :open_timeout => 10,
      :read_timeout => 10,

      # Disable logging for cleaner spec output.
      :log => false
    )

    response = call_and_fail_gracefully(client, :verify_email, :message => { :email => "soap@example.com", "LicenseKey" => "?" })

    response_text = response.body[:verify_email_response][:verify_email_result][:response_text]

    if response_text == "Current license key only allows so many checks"
      # Fallback to not fail the specs when the service's API limit is reached,
      # but to mark the spec as pending instead.
      pending "API limit exceeded"
    else
      # The expected result. We unfortunately don't have a license key for this service.
      response_text.should == "Email Domain Not Found"
    end
  end

end
