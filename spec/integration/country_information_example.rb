require "spec_helper"

describe "Country Information Example" do
  it "supports a streamed response where chunks are passed in a block" do
    client = Savon.client(
      :wsdl => "http://webservices.oorsprong.org/websamples.countryinfo/CountryInfoService.wso?WSDL",
      :read_timeout => 10,
      :open_timeout => 10,
      :log => false
    )

    body = ""
    chunk_counter = 0
    response = client.streamed_call(:full_country_info_all_countries) do |data|
      chunk_counter += 1
      body += data
    end
    expect(body.size).to_not eql(0)
    expect(chunk_counter).to_not eql(0)
    expect(response.http.body).to eql("")
  end
end
