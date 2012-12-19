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
      # For the corrent values to pass for :from_unit and :to_unit, I searched the WSDL for
      # the "FromUnit" type which is a "TemperatureUnit" enumeration that looks like this:
      #
      # <s:simpleType name="TemperatureUnit">
      #   <s:restriction base="s:string">
      #     <s:enumeration value="degreeCelsius"/>
      #     <s:enumeration value="degreeFahrenheit"/>
      #     <s:enumeration value="degreeRankine"/>
      #     <s:enumeration value="degreeReaumur"/>
      #     <s:enumeration value="kelvin"/>
      #   </s:restriction>
      # </s:simpleType>
      #
      # Support for XS schema types needs to be improved.
      message(:station => { :id => 1975 }, :limit => 1)
    end

    station_name = response.body[:get_stations_response][:return][:stations][:name]
    expect(station_name).to eq("Cite")
  end

end
