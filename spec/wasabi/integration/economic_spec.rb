require 'spec_helper'

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

    # XXX: this might be useless now that almost everything is parsed lazily.
    it 'has an ok parse-time for huge wsdl files' do
      #profiler = MethodProfiler.observe(Wasabi::Parser)
      operations = wsdl.operations('EconomicWebService', 'EconomicWebServiceSoap')
      expect(operations.count).to eq(1511)
      #puts profiler.report
    end

  end
end
