 require "spec_helper"

describe "RATP example" do

  it "retrieves information about a specific station" do
    client = Savon.client do
      # The WSDL document provided by the service.
      wsdl "http://www.ratp.fr/wsiv/services/Wsiv?wsdl"

      # Lower timeouts so these specs don't take forever when the service is not available.
      open_timeout 10
      read_timeout 10

      # Disable logging for cleaner spec output.
      log false
    end

    response = client.call(:get_stations) do
      message(:station => { :id => 1975 }, :limit => 1)
    end

    station_name = response.body[:get_stations_response][:return][:stations][:name]
    expect(station_name).to eq("Cite")
  end

end
