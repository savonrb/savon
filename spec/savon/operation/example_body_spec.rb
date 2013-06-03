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

  describe '#example_body' do
    it 'returns an Array with a single Hash for Arrays of complex types' do
      expect(add_logins.example_body).to eq(
        addLogins: {

          # array of complex types
          accounts: [
            {
              username: 'string',
              password: 'string',
              contactInformation: {
                organization: 'string',
                firstName: 'string',
                lastName: 'string',
                email: 'string',
                phone: 'string',
                address: 'string',
                address2: 'string',
                city: 'string',
                state: 'string',
                zip: 'string',
                country: 'string',
                notes: 'string'
              },
              permissionAgencyAdmin: 'boolean',
              permissionAdmin: 'boolean',
              permissionApi: 'boolean',
              permissionUpgrade: 'boolean',
              permissionFatigueOverride: 'boolean',
              permissionMessageCompose: 'boolean',
              permissionMessageApprove: 'boolean',
              permissionMessageDelete: 'boolean',
              permissionAutomatorCompose: 'boolean',
              permissionListCreateSend: 'boolean',
              permissionListCreate: 'boolean',
              permissionSegmentCreate: 'boolean',
              permissionFieldCreate: 'boolean',
              permissionFieldReorder: 'boolean',
              permissionSubscriberCreate: 'boolean',
              permissionSubscriberView: 'boolean'
            }
          ]
        }
      )
    end

    it 'returns an Array with a single simple type for Arrays of simple types' do
      expect(get_mu_bets_lite.example_body).to eq(
        getMUBetsLite: {
          request: {
            header: {
              clientStamp: 'long',
              sessionToken: 'string'
            },
            betStatus: 'string',
            marketId: 'int',
            betIds: {

              # array of simple types
              betId: ['long']

            },
            orderBy: 'string',
            sortOrder: 'string',
            recordCount: 'int',
            startRecord: 'int',
            matchedSince: 'dateTime',
            excludeLastSecond: 'boolean'
          }
        }
      )
    end
  end

end
