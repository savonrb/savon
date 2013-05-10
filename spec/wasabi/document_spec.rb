require 'spec_helper'

describe Wasabi::Document do

  describe '#bindings' do
    it 'works with multiple bindings' do
      document = get_documents(:oracle).first

      expect(document.bindings.keys).to match_array([
        'ConditionService', 'HtmlViewService', 'IBotService', 'JobManagementService',
        'MetadataService', 'ReplicationService', 'ReportEditingService', 'SAWSessionService',
        'SecurityService', 'WebCatalogService', 'XmlViewService'
      ])

      # binding

      binding = document.bindings['SecurityService']

      expect(binding.name).to eq('SecurityService')
      expect(binding.port_type).to eq('sawsoap:SecurityServiceSoap')
      expect(binding.style).to eq('document')
      expect(binding.transport).to eq('http://schemas.xmlsoap.org/soap/http')

      expect(binding.operations.keys).to match_array([
        'forgetAccounts', 'getAccountTenantID', 'getAccounts', 'getGlobalPrivilegeACL',
        'getGlobalPrivileges', 'getGroups', 'getMembers', 'getPermissions', 'getPrivilegesStatus',
        'isMember', 'joinGroups', 'leaveGroups', 'renameAccounts', 'updateGlobalPrivilegeACL'
      ])

      # binding operation

      binding_operation = binding.operations['getAccounts']
      expect(binding_operation.name).to eq('getAccounts')

      expect(binding_operation.soap_action).to eq('#getAccounts')
      expect(binding_operation.style).to eq('document')
    end
  end

  describe '#services' do
    it 'works with multiple services' do
      document = get_documents(:oracle).first

      expect(document.services.keys).to match_array([
        'SAWSessionService', 'WebCatalogService', 'XmlViewService', 'SecurityService',
        'ConditionService', 'HtmlViewService', 'IBotService', 'JobManagementService',
        'MetadataService', 'ReplicationService', 'ReportEditingService'
      ])

      service = document.services['ConditionService']
      expect(service.ports.keys).to eq(['ConditionServiceSoap'])

      # soap 1.1 port

      soap_port = service.ports['ConditionServiceSoap']

      expect(soap_port.name).to eq('ConditionServiceSoap')
      expect(soap_port.binding).to eq('sawsoap:ConditionService')

      expect(soap_port.type).to eq(Wasabi::SOAP_1_1)
      expect(soap_port.location).to eq('https://fap0023-bi.oracleads.com/analytics-ws/saw.dll?SoapImpl=conditionService')
    end

    it 'only knows about the SOAP ports of each service' do
      document = get_documents(:email_validation).first

      expect(document.services.keys).to eq(['EmailVerNoTestEmail'])

      service = document.services['EmailVerNoTestEmail']
      expect(service.ports.keys).to match_array([
        'EmailVerNoTestEmailSoap', 'EmailVerNoTestEmailSoap12'
      ])

      # soap 1.1 port

      soap_1_1_port = service.ports['EmailVerNoTestEmailSoap']

      expect(soap_1_1_port.name).to eq('EmailVerNoTestEmailSoap')
      expect(soap_1_1_port.binding).to eq('tns:EmailVerNoTestEmailSoap')

      expect(soap_1_1_port.type).to eq(Wasabi::SOAP_1_1)
      expect(soap_1_1_port.location).to eq('http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx')

      # soap 1.2 port

      soap_1_2_port = service.ports['EmailVerNoTestEmailSoap12']

      expect(soap_1_2_port.name).to eq('EmailVerNoTestEmailSoap12')
      expect(soap_1_2_port.binding).to eq('tns:EmailVerNoTestEmailSoap12')

      expect(soap_1_2_port.type).to eq(Wasabi::SOAP_1_2)
      expect(soap_1_2_port.location).to eq('http://ws.cdyne.com/emailverify/Emailvernotestemail.asmx')
    end
  end

  def get_documents(fixture_name)
    xml = fixture(fixture_name).read
    Wasabi.new(xml).documents
  end

end
