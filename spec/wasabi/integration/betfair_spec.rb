require 'spec_helper'

describe Wasabi do
  context 'with: betfair.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:betfair).read }

    it 'returns a map of services and ports' do
      expect(wsdl.services).to eq(
        'BFExchangeService' => {
          :ports => {
            'BFExchangeService' => {
              :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
              :location => 'https://api.betfair.com/exchange/v5/BFExchangeService'
            }
          }
        }
      )
    end

    it 'knows operations with extensions and Arrays' do
      service = port = 'BFExchangeService'

      operation = wsdl.operation(service, port, 'getMUBetsLite')

      expect(operation.soap_action).to eq('getMUBetsLite')
      expect(operation.endpoint).to eq('https://api.betfair.com/exchange/v5/BFExchangeService')

      expect(operation.input.count).to eq(1)

      ns = 'http://www.betfair.com/publicapi/v5/BFExchangeService/'
      ns2 = 'http://www.betfair.com/publicapi/types/exchange/v5/'

      get_mu_bets_lite = wsdl.schemas.element(ns, 'getMUBetsLite')
      request = get_mu_bets_lite.collect_child_elements.first

      expect(operation.input.first.to_a).to eq([
        [['getMUBetsLite'],
          { namespace: ns, form: 'qualified',   singular: true }],

        [['getMUBetsLite', 'request'],
          { namespace: ns, form: 'qualified',   singular: true }],

        # extension elements

        [['getMUBetsLite', 'request', 'header'],
           { namespace: ns2, form: 'unqualified', singular: true }],

        [['getMUBetsLite', 'request', 'header', 'clientStamp'],
           { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:long' }],

        [['getMUBetsLite', 'request', 'header', 'sessionToken'],
           { namespace: ns2, form: 'unqualified', singular: true, type: 'xsd:string' }],

        # ---

        [['getMUBetsLite', 'request', 'betStatus'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:string' }],

        [['getMUBetsLite', 'request', 'marketId'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:int' }],

        [['getMUBetsLite', 'request', 'betIds'],
          { namespace: ns2, form: 'unqualified', singular: true }],

        [['getMUBetsLite', 'request', 'betIds', 'betId'],
          { namespace: ns2, form: 'qualified',   singular: false, type: 'xsd:long' }],

        [['getMUBetsLite', 'request', 'orderBy'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:string' }],

        [['getMUBetsLite', 'request', 'sortOrder'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:string' }],

        [['getMUBetsLite', 'request', 'recordCount'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:int' }],

        [['getMUBetsLite', 'request', 'startRecord'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:int' }],

        [['getMUBetsLite', 'request', 'matchedSince'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:dateTime' }],

        [['getMUBetsLite', 'request', 'excludeLastSecond'],
          { namespace: ns2, form: 'unqualified', singular: true,  type: 'xsd:boolean' }]
      ])
    end

  end
end
