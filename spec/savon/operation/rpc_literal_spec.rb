require 'spec_helper'

describe Savon::Operation do

  # namespace reference:
  #   http://www.ibm.com/developerworks/webservices/library/ws-tip-namespace/index.html
  context 'with an rpc/literal document' do
    it 'qualifies the RPC wrapper with the soap:body namespace' do
      client = Savon.new fixture('wsdl/rpc_literal')

      op1 = client.operation('SampleService', 'Sample', 'op1')
      expect(op1.input_style).to eq('rpc/literal')

      expect(op1.body_parts).to eq([
        [ ['in'],          { namespace: nil,                        form: 'unqualified', singular: true } ],
        [ ['in', 'data1'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['in', 'data2'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ]
      ])
    end

    it 'qualifies the RPC wrapper with the soap:body namespace (which differs from the tns)' do
      client = Savon.new fixture('wsdl/rpc_literal')

      op2 = client.operation('SampleService', 'Sample', 'op2')
      expect(op2.input_style).to eq('rpc/literal')

      expect(op2.body_parts).to eq([
        [ ['in'],          { namespace: nil,                        form: 'unqualified', singular: true } ],
        [ ['in', 'data1'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['in', 'data2'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ]
      ])
    end

    it 'does not qualify the RPC wrapper without a soap:body namespace and follows element refs' do
      client = Savon.new fixture('wsdl/rpc_literal')

      op3 = client.operation('SampleService', 'Sample', 'op3')
      expect(op3.input_style).to eq('rpc/literal')

      expect(op3.body_parts).to eq([
        [ ['DataElem'],           { namespace: 'http://dataNamespace.com', form: 'qualified',   singular: true } ],
        [ ['DataElem', 'data1'],  { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['DataElem', 'data2'],  { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['in2'],                { namespace: nil,                        form: 'unqualified', singular: true } ],
        [ ['in2', 'RefDataElem'], { namespace: 'http://refNamespace.com',  form: 'qualified',   singular: true, type: 'int' } ],
      ])
    end
  end

end
