require 'spec_helper'

describe Savon::Operation do

  let(:add_logins) {
    client = Savon.new fixture('wsdl/bronto')

    service_name = :BrontoSoapApiImplService
    port_name    = :BrontoSoapApiImplPort

    client.operation(service_name, port_name, :addLogins)
  }

  let(:get_mu_bets_lite) {
    client = Savon.new fixture('wsdl/betfair')

    service_name = port_name = :BFExchangeService
    client.operation(service_name, port_name, :getMUBetsLite)
  }

  let(:vatAccount_update_from_data_array) {
    client = Savon.new fixture('wsdl/arrays_with_attributes')

    service, port = "EconomicWebService", "EconomicWebServiceSoap"

    client.operation(service, port, 'VatAccount_UpdateFromDataArray')
  }

  describe '#build' do
    it 'expects Arrays of complex types as Arrays of Hashes' do
      add_logins.body = {
        addLogins: {

          # accounts in an array of complex types
          # which can be represented by hashes.
          accounts: [
            {
              username: 'first',
              password: 'secret',
              contactInformation: {
                email: 'first@example.com',
              }
            },
            {
              username: 'second',
              password: 'ubersecret',
              contactInformation: {
                email: 'second@example.com',
              }
            }
          ]
        }
      }

      expected = Nokogiri.XML('
        <env:Envelope
            xmlns:lol0="http://api.bronto.com/v4"
            xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header>
          </env:Header>
          <env:Body>
            <lol0:addLogins>
              <accounts>
                <username>first</username>
                <password>secret</password>
                <contactInformation>
                  <email>first@example.com</email>
                </contactInformation>
              </accounts>
              <accounts>
                <username>second</username>
                <password>ubersecret</password>
                <contactInformation>
                  <email>second@example.com</email>
                </contactInformation>
              </accounts>
            </lol0:addLogins>
          </env:Body>
        </env:Envelope>
      ')

      expect(Nokogiri.XML add_logins.build).
        to be_equivalent_to(expected).respecting_element_order
    end

    it 'raises if it did not receive a Hash for a singular complex type' do
      add_logins.body = {
        addLogins: [
          {
            accounts: {
              username: 'test'
            }
          }
        ]
      }

      expect { add_logins.build }.
        to raise_error(ArgumentError, "Expected a Hash for the :addLogins complex type")
    end

    it 'raises if it did not receive an Array for an Array of complex types' do
      add_logins.body = {
        addLogins: {

          # accounts is an array and we expect the value
          # to be an array of hashes to reflect this.
          accounts: {
            username: 'test'
          }
        }
      }

      expect { add_logins.build }.
        to raise_error(ArgumentError, "Expected an Array of Hashes for the :accounts complex type")
    end

    it 'raises if it received an Array for a singular simple type' do
      add_logins.body = {
        addLogins: {
          accounts: [
            {
              username: ['multiple', 'tests']
            }
          ]
        }
      }

      expect { add_logins.build }.
        to raise_error(ArgumentError, "Unexpected Array for the :username simple type")
    end

    it 'expectes Arrays of simple types to be represented as Arrays of values' do
      get_mu_bets_lite.body = {
        getMUBetsLite: {
          request: {
            betIds: {
              betId: [1, 2, 3]
            }
          }
        }
      }

      expected = Nokogiri.XML(%{
        <env:Envelope
            xmlns:lol0="http://www.betfair.com/publicapi/v5/BFExchangeService/"
            xmlns:lol1="http://www.betfair.com/publicapi/types/exchange/v5/"
            xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header/>
          <env:Body>
            <lol0:getMUBetsLite>
              <lol0:request>
                <betIds>
                  <lol1:betId>1</lol1:betId>
                  <lol1:betId>2</lol1:betId>
                  <lol1:betId>3</lol1:betId>
                </betIds>
              </lol0:request>
            </lol0:getMUBetsLite>
          </env:Body>
        </env:Envelope>
      })

      expect(Nokogiri.XML get_mu_bets_lite.build).
        to be_equivalent_to(expected).respecting_element_order
    end

    it 'raises if it did not receive an Array for an Array of simple types' do
      get_mu_bets_lite.body = {
        getMUBetsLite: {
          request: {
            betIds: {
              betId: 1
            }
          }
        }
      }

      expect { get_mu_bets_lite.build }.
        to raise_error(ArgumentError, "Expected an Array of values for the :betId simple type")
    end

    it 'expects Array of Hashes with attributes to return Array of complex types with attributes' do
      vatAccount_update_from_data_array.body = {
          :VatAccount_UpdateFromDataArray => {
              :dataArray => {
                  :VatAccountData => [
                      {
                          :Handle => {:VatCode => "VAT123"},
                          :VatCode => "VAT123",
                          :Name => "ITS",
                          :Type => "Ltd",
                          :RateAsPercent => 17.5,
                          :AccountHandle => {:Number => 123}, :ContraAccountHandle => {:Number => 456},
                          :_Thaco => "Testing 1234"
                      },
                      {
                          :Handle => {:VatCode => "VAT987"},
                          :VatCode => "VAT987",
                          :Name => "Banana",
                          :Type => "PLC",
                          :RateAsPercent => 21.12,
                          :AccountHandle => {:Number => 876}, :ContraAccountHandle => {:Number => 8756},
                          :_Thaco => "Testing 5678"
                      }
                  ]
              }
          }
      }

      expected = Nokogiri.XML(%{
        <env:Envelope xmlns:lol0="http://e-conomic.com" xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
          <env:Header>
          </env:Header>
          <env:Body>
            <lol0:VatAccount_UpdateFromDataArray>
              <lol0:dataArray>
                <lol0:VatAccountData Thaco="Testing 1234">
                  <lol0:Handle>
                    <lol0:VatCode>VAT123</lol0:VatCode>
                  </lol0:Handle>
                  <lol0:VatCode>VAT123</lol0:VatCode>
                  <lol0:Name>ITS</lol0:Name>
                  <lol0:Type>Ltd</lol0:Type>
                  <lol0:RateAsPercent>17.5</lol0:RateAsPercent>
                  <lol0:AccountHandle>
                    <lol0:Number>123</lol0:Number>
                  </lol0:AccountHandle>
                  <lol0:ContraAccountHandle>
                    <lol0:Number>456</lol0:Number>
                  </lol0:ContraAccountHandle>
                </lol0:VatAccountData>
                <lol0:VatAccountData Thaco="Testing 5678">
                  <lol0:Handle>
                    <lol0:VatCode>VAT987</lol0:VatCode>
                  </lol0:Handle>
                  <lol0:VatCode>VAT987</lol0:VatCode>
                  <lol0:Name>Banana</lol0:Name>
                  <lol0:Type>PLC</lol0:Type>
                  <lol0:RateAsPercent>21.12</lol0:RateAsPercent>
                  <lol0:AccountHandle>
                    <lol0:Number>876</lol0:Number>
                  </lol0:AccountHandle>
                  <lol0:ContraAccountHandle>
                    <lol0:Number>8756</lol0:Number>
                  </lol0:ContraAccountHandle>
                </lol0:VatAccountData>
              </lol0:dataArray>
            </lol0:VatAccount_UpdateFromDataArray>
          </env:Body>
        </env:Envelope>})

      expect(Nokogiri.XML vatAccount_update_from_data_array.build).
          to be_equivalent_to(expected).respecting_element_order
    end
  end

end
