require 'spec_helper'

describe Savon::Operation do

  # namespace reference:
  #   http://www.ibm.com/developerworks/webservices/library/ws-tip-namespace/index.html
  context 'with a document/literal wrapped document' do
    it 'works for op1' do
      client = Savon.new fixture('wsdl/document_literal_wrapped')

      op1 = client.operation('SampleService', 'Sample', 'op1')
      expect(op1.input_style).to eq('document/literal')

      expect(op1.body_parts).to eq([
        [ ['op1'],                { namespace: 'http://apiNamespace.com',  form: 'qualified',   singular: true } ],
        [ ['op1', 'in'],          { namespace: 'http://apiNamespace.com',  form: 'unqualified', singular: true } ],
        [ ['op1', 'in', 'data1'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['op1', 'in', 'data2'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ]
      ])
    end

    it 'works for op2' do
      client = Savon.new fixture('wsdl/document_literal_wrapped')

      op2 = client.operation('SampleService', 'Sample', 'op2')
      expect(op2.input_style).to eq('document/literal')

      expect(op2.body_parts).to eq([
        [ ['op2'],                { namespace: 'http://apiNamespace.com',  form: 'qualified',   singular: true } ],
        [ ['op2', 'in'],          { namespace: 'http://apiNamespace.com',  form: 'unqualified', singular: true } ],
        [ ['op2', 'in', 'data1'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['op2', 'in', 'data2'], { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ]
      ])
    end

    it 'works for op3' do
      client = Savon.new fixture('wsdl/document_literal_wrapped')

      op3 = client.operation('SampleService', 'Sample', 'op3')
      expect(op3.input_style).to eq('document/literal')

      expect(op3.body_parts).to eq([
        [ ['op3'],                       { namespace: 'http://apiNamespace.com',  form: 'qualified',   singular: true } ],
        [ ['op3', 'DataElem'],           { namespace: 'http://dataNamespace.com', form: 'qualified',   singular: true } ],
        [ ['op3', 'DataElem', 'data1'],  { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['op3', 'DataElem', 'data2'],  { namespace: 'http://dataNamespace.com', form: 'unqualified', singular: true, type: 'int' } ],
        [ ['op3', 'in2'],                { namespace: 'http://apiNamespace.com',  form: 'unqualified', singular: true } ],
        [ ['op3', 'in2', 'RefDataElem'], { namespace: 'http://refNamespace.com',  form: 'qualified',   singular: true, type: 'int' } ],
      ])
    end
  end

end
