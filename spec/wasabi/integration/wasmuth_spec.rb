require 'spec_helper'

describe Wasabi do
  context 'with: wasmuth.wsdl' do

    subject(:wsdl) { Wasabi.new(wsdl_url, http_mock) }

    let(:wsdl_url)  { 'http://www3.mediaservice-wasmuth.de/online-ws-2.0/OnlineSync?wsdl' }

    before do
      http_mock.fake_request(wsdl_url, 'wasmuth/wasmuth.wsdl')

      # 2 schemas to import.
      schema_import_base = 'http://www3.mediaservice-wasmuth.de:80/online-ws-2.0/OnlineSync?xsd=%d'
      http_mock.fake_request(schema_import_base % 1, "wasmuth/wasmuth1.xsd")
      http_mock.fake_request(schema_import_base % 2, "wasmuth/wasmuth2.xsd")
    end

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'OnlineSyncService' => {
          :ports => {
            'OnlineSyncPort' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'http://www3.mediaservice-wasmuth.de:80/online-ws-2.0/OnlineSync'
            }
          }
        }
      )
    end

    it 'knows the operations' do
      operation = wsdl.operation('OnlineSyncService', 'OnlineSyncPort', 'getStTables')

      expect(operation.soap_action).to eq('')
      expect(operation.endpoint).to eq('http://www3.mediaservice-wasmuth.de:80/online-ws-2.0/OnlineSync')

      expect(operation.input.count).to eq(1)

      namespace = 'http://ws.online.msw/'

      expect(operation.input.first.to_a).to eq([
        [['getStTables'],             { namespace: namespace, form: 'qualified',   singular: true }],
        [['getStTables', 'username'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
        [['getStTables', 'password'], { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }],
        [['getStTables', 'version'],  { namespace: namespace, form: 'unqualified', singular: true, type: 'xs:string' }]
      ])
    end

  end
end

