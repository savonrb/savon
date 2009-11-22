require "spec_helper"

describe Savon::Service do
  before { @proxy = Savon::Service.new SpecHelper.some_endpoint }

  describe "method_missing" do
    describe "with per request configurations" do

      it "handles WSSE authentication" do
        @proxy.find_user :soap_body => {}, :wsse => {
          :username => "thedude", :password => "secret"
        }
  
        request_body = @proxy.http_request.body
        request_body.should include *SpecHelper.wsse_security_nodes
        request_body.should include the_unencrypted_wsse_password
      end
  
      it "handles WSSE digest authentication" do
        @proxy.find_user :soap_body => {}, :wsse => {
          :username => "thedude", :password => "secret", :digest => true
        }
  
        request_body = @proxy.http_request.body
        request_body.should include *SpecHelper.wsse_security_nodes
        request_body.should_not include the_unencrypted_wsse_password
      end
  
      def the_unencrypted_wsse_password
        "<wsse:Password>#{savon_config.wsse_password}</wsse:Password>"
      end

    end
  end

end