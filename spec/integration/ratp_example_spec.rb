 require "spec_helper"

describe "RATP example" do

  it "retrieves information about a specific station" do
    client = Savon.new(
      # The WSDL document provided by the service.
      :wsdl => "http://www.ratp.fr/wsiv/services/Wsiv?wsdl",

      # Lower timeouts so these specs don't take forever when the service is not available.
      :open_timeout => $integration_test_timeout,
      :read_timeout => $integration_test_timeout,

      # Disable logging for cleaner spec output.
      :log => false
    )

    # XXX: the service seems to rely on the order of arguments.
    #      try to fix this with the new wsdl parser.
    message = { :station => { :id => 1975 }, :limit => 1 }
    response = call_and_fail_gracefully(client, :get_stations, :message => message)

    station_name = response.body[:get_stations_response][:return][:stations][:name]
    expect(station_name).to eq("Cite")
  end

end
