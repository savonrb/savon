 require 'spec_helper'

describe 'Integration with RATP' do

  subject(:client) { Savon.new fixture('wsdl/ratp') }

  let(:service_name) { :Wsiv }
  let(:port_name)    { :WsivSOAP11port_http }

  it 'returns a map of services and ports' do
    expect(client.services).to eq(
      'Wsiv' => {
        :ports => {
          'WsivSOAP11port_http' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap/',
            :location => 'http://www.ratp.fr/wsiv/services/Wsiv'
          },
          'WsivSOAP12port_http' => {
            :type     => 'http://schemas.xmlsoap.org/wsdl/soap12/',
            :location => 'http://www.ratp.fr/wsiv/services/Wsiv'
          }
        }
      }
    )
  end

  it 'gracefully handle recursive type definitions' do
    service, port = 'Wsiv', 'WsivSOAP11port_http'
    operation = client.operation(service, port, 'getStations')

    expect(operation.soap_action).to eq('urn:getStations')
    expect(operation.endpoint).to eq('http://www.ratp.fr/wsiv/services/Wsiv')

    ns1 = 'http://wsiv.ratp.fr'
    ns2 = 'http://wsiv.ratp.fr/xsd'

    expect(operation.body_parts).to eq([
      [['getStations'],                                                       { namespace: ns1, form: 'qualified', singular: true }],
      [['getStations', 'station'],                                            { namespace: ns1, form: 'qualified', singular: true }],
      [['getStations', 'station', 'direction'],                               { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'direction', 'line'],                       { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'direction', 'line', 'code'],               { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'codeStif'],           { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'id'],                 { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'image'],              { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'name'],               { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'realm'],              { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'reseau'],             { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'direction', 'line', 'reseau', 'code'],     { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'reseau', 'id'],       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'reseau', 'image'],    { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'line', 'reseau', 'name'],     { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'name'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'direction', 'sens'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],

      [['getStations', 'station', 'direction', 'stationsEndLine'],
        # Notice how this recursively references its parent type, so we return the
        # type it references as the :recursive_type.
        { namespace: ns2, form: 'qualified', singular: false, recursive_type: 'ax21:Station' }],

      [['getStations', 'station', 'geoPointA'],                               { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'geoPointA', 'id'],                         { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointA', 'name'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointA', 'nameSuffix'],                 { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointA', 'type'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointA', 'x'],                          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'station', 'geoPointA', 'y'],                          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'station', 'geoPointR'],                               { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'geoPointR', 'id'],                         { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointR', 'name'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointR', 'nameSuffix'],                 { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointR', 'type'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'geoPointR', 'x'],                          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'station', 'geoPointR', 'y'],                          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'station', 'id'],                                      { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'idsNextA'],                                { namespace: ns2, form: 'qualified', singular: false, type: 'xs:string' }],
      [['getStations', 'station', 'idsNextR'],                                { namespace: ns2, form: 'qualified', singular: false, type: 'xs:string' }],
      [['getStations', 'station', 'line'],                                    { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'line', 'code'],                            { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'codeStif'],                        { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'id'],                              { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'image'],                           { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'name'],                            { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'realm'],                           { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'reseau'],                          { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'line', 'reseau', 'code'],                  { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'reseau', 'id'],                    { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'reseau', 'image'],                 { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'line', 'reseau', 'name'],                  { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'name'],                                    { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea'],                             { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'stationArea', 'access'],                   { namespace: ns2, form: 'qualified', singular: false }],
      [['getStations', 'station', 'stationArea', 'access', 'address'],        { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'id'],             { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'index'],          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'name'],           { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'timeDaysLabel'],  { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'timeDaysStatus'], { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'timeEnd'],        { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'timeStart'],      { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'access', 'x'],              { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'station', 'stationArea', 'access', 'y'],              { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'station', 'stationArea', 'id'],                       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'name'],                     { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],

      [['getStations', 'station', 'stationArea', 'stations'],
        # Another recursive type definition.
        { namespace: ns2, form: 'qualified', singular: false, recursive_type: 'ax21:Station' }],

      [['getStations', 'station', 'stationArea', 'tarifsToParis'],                               { namespace: ns2, form: 'qualified', singular: false }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'demiTarif'],                  { namespace: ns2, form: 'qualified', singular: true, type: 'xs:float' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'pleinTarif'],                 { namespace: ns2, form: 'qualified', singular: true, type: 'xs:float' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine'],                    { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'code'],            { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'codeStif'],        { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'id'],              { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'image'],           { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'name'],            { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'realm'],           { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'reseau'],          { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'reseau', 'code'],  { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'reseau', 'id'],    { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'reseau', 'image'], { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaLine', 'reseau', 'name'],  { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaReseau'],                  { namespace: ns2, form: 'qualified', singular: true }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaReseau', 'code'],          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaReseau', 'id'],            { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaReseau', 'image'],         { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'tarifsToParis', 'viaReseau', 'name'],          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'station', 'stationArea', 'zoneCarteOrange'],                             { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],

      [['getStations', 'gp'],               { namespace: ns1, form: 'qualified', singular: true }],
      [['getStations', 'gp', 'id'],         { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'gp', 'name'],       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'gp', 'nameSuffix'], { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'gp', 'type'],       { namespace: ns2, form: 'qualified', singular: true, type: 'xs:string' }],
      [['getStations', 'gp', 'x'],          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'gp', 'y'],          { namespace: ns2, form: 'qualified', singular: true, type: 'xs:double' }],
      [['getStations', 'distances'],        { namespace: ns1, form: 'qualified', singular: false, type: 'xs:int' }],
      [['getStations', 'limit'],            { namespace: ns1, form: 'qualified', singular: true, type: 'xs:int' }],
      [['getStations', 'sortAlpha'],        { namespace: ns1, form: 'qualified', singular: true, type: 'xs:boolean' }]
    ])
  end

  it 'builds a request' do
    operation = client.operation(service_name, port_name, :getStations)

    operation.body = {
      getStations: {
        station: {
          id: 1975
        },
        limit: 1
      }
    }

    expected = Nokogiri.XML(%{
      <env:Envelope
          xmlns:lol0="http://wsiv.ratp.fr"
          xmlns:lol1="http://wsiv.ratp.fr/xsd"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:getStations>
            <lol0:station>
              <lol1:id>1975</lol1:id>
            </lol0:station>
            <lol0:limit>1</lol0:limit>
          </lol0:getStations>
        </env:Body>
      </env:Envelope>
    })

    expect(Nokogiri.XML operation.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
