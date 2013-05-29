require 'spec_helper'
require 'benchmark'

describe Wasabi do
  context 'with: economic.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:economic).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'EconomicWebService' => {
          :ports => {
            'EconomicWebServiceSoap'   => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'https://api.e-conomic.com/secure/api1/EconomicWebservice.asmx'
            },
            'EconomicWebServiceSoap12' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap12/',
              :location => 'https://api.e-conomic.com/secure/api1/EconomicWebservice.asmx'
            }
          }
        }
      )
    end

    it 'knows operations with Arrays' do
      service, port = 'EconomicWebService', 'EconomicWebServiceSoap'
      operation = wsdl.operation(service, port, 'Account_GetDataArray')

      expect(operation.soap_action).to eq('http://e-conomic.com/Account_GetDataArray')
      expect(operation.endpoint).to eq('https://api.e-conomic.com/secure/api1/EconomicWebservice.asmx')

      expect(operation.input.count).to eq(1)

      namespace = 'http://e-conomic.com'

      expect(operation.input.first.to_a).to eq([
        [['Account_GetDataArray'], { namespace: namespace, form: 'qualified', singular: true }],
        [['Account_GetDataArray', 'entityHandles'], { namespace: namespace, form: 'qualified', singular: true }],
        [['Account_GetDataArray', 'entityHandles', 'AccountHandle'], { namespace: namespace, form: 'qualified', singular: false }],
        [['Account_GetDataArray', 'entityHandles', 'AccountHandle', 'Number'], { namespace: namespace, form: 'qualified', type: 's:int', singular: true }]
      ])
    end

    it 'has an ok parse-time for huge wsdl files' do
      #profiler = MethodProfiler.observe(Wasabi::Parser)
      parse_time = Benchmark.realtime {
        wsdl.operations('EconomicWebService', 'EconomicWebServiceSoap')
      }
      #puts profiler.report

      # this probably needs to be increased for travis or other rubies,
      # but it should prevent major performance problems.
      expect(parse_time).to be < 1.0
    end

  end
end
