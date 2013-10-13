require 'spec_helper'

describe 'rpc/encoded binding test' do

  it 'should should work with WSDLs that have rpc/encoded SOAP binding' do
    client = Savon.client(
        :wsdl => "http://www.boyzoid.com/comp/randomQuote.cfc?wsdl",
        :open_timeout => 10,
        :read_timeout => 10,
        :log => false
    )

    begin
      client.call(:get_quote)
    rescue Savon::SOAPFault => e
      $stderr.puts e.to_hash.inspect
      f_c = e.to_hash[:fault][:faultstring]
      f_c.should_not  == 'No such operation \'getQuoteRequest\''
      f_c.should == 'soapenv:Server.userException'
      pending e
    end
  end
end
