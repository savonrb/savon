require "spec_helper"

describe "Country Information Example" do
  it "retrieves information about all countries using streamed response" do
    client = Savon.client(
      :wsdl => "http://webservices.oorsprong.org/websamples.countryinfo/CountryInfoService.wso?WSDL",
      :read_timeout => 10,
      :open_timeout => 10,
      :log => false
    )

    response = ""
    chunk_counter = 0
    result = client.streamed_call(:full_country_info_all_countries) do |data|
      chunk_counter += 1
      response += data
    end
    expect(response.size).to_not eql(0)
    expect(chunk_counter).to_not eql(0)
  end
end
