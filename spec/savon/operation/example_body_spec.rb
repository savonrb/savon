require 'spec_helper'

describe Savon::Operation do

  describe '#example_body' do
    it 'returns an Array with one entry for Arrays of complex types' do
      client = Savon.new fixture('wsdl/bronto')

      service_name = :BrontoSoapApiImplService
      port_name    = :BrontoSoapApiImplPort

      operation = client.operation(service_name, port_name, :addLogins)

      expect(operation.example_body).to eq(
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
  end

end
