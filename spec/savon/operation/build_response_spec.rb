require 'spec_helper'

describe Savon::Operation do

  let(:add_logins) {
    client = Savon.new fixture('wsdl/bronto')

    service_name = :BrontoSoapApiImplService
    port_name = :BrontoSoapApiImplPort

    client.operation(service_name, port_name, :addLogins)
  }

  describe "#build_response" do
    it "expects an Array of complex types as an Array of Hashes" do
      add_logins.response_body = {
          :addLoginsResponse => {
              :return => {
                  :errors => [123, 456],
                  :results => [
                      {:id => 123, :isNew => true, :isError => true, :errorString => "Something has gone wrong."},
                      {:id => 456, :isNew => false, :isError => false, :errorString => "This isn't an error."}
                  ]
              }
          }
      }

      expected = Nokogiri.XML(%{
        <env:Envelope
          xmlns:lol0="http://api.bronto.com/v4"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header>
          </env:Header>
          <env:Body>
            <lol0:addLoginsResponse>
               <return>
                  <errors>123</errors>
                  <errors>456</errors>
                  <results>
                    <id>123</id>
                    <isNew>true</isNew>
                    <isError>true</isError>
                    <errorString>Something has gone wrong.</errorString>
                  </results>
                  <results>
                    <id>456</id>
                    <isNew>false</isNew>
                    <isError>false</isError>
                    <errorString>This isn't an error.</errorString>
                  </results>
               </return>
            </lol0:addLoginsResponse>
          </env:Body>
        </env:Envelope>
      })

      result = Nokogiri.XML(add_logins.build_response)

      expect(result).to be_equivalent_to(expected).respecting_element_order
    end
  end
end