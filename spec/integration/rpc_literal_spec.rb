require 'spec_helper'

describe 'Integration with an RPC/Literal example' do

  subject(:client) { Savon.new fixture('wsdl/rpc_literal') }

  let(:service_name) { :SampleService }
  let(:port_name)    { :Sample }

  it 'works with op1' do
    op1 = client.operation(service_name, port_name, :op1)

    # Check the example request.
    expect(op1.example_request).to eq(
      in: {
        data1: 'int',
        data2: 'int'
      }
    )

    # Build the request. It returns a Hash without the RPC wrapper element,
    # because users just don't need to care about it.
    actual = Nokogiri.XML op1.build(
      message: {
        in: {
          data1: 24,
          data2: 36
        }
      }
    )

    # The expected request.
    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://apiNamespace.com"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:op1>
            <in>
              <data1>24</data1>
              <data2>36</data2>
            </in>
          </lol0:op1>
        </env:Body>
      </env:Envelope>
    ')

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

  it 'works with op3' do
    op3 = client.operation(service_name, port_name, :op3)

    # Check the example request.
    expect(op3.example_request).to eq(
      DataElem: {
        data1: 'int',
        data2: 'int'
      },
      in2: {
        RefDataElem: 'int'
      }
    )

    # Build the request.
    actual = Nokogiri.XML op3.build(
      message: {
        DataElem: {
          data1: 64,
          data2: 128
        },
        in2: {
          RefDataElem: 3
        }
      }
    )

    # The expected request. Notice how the RPC wrapper element 'op3' is not
    # namespaced because the WSDL does not define a namespace for it.
    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://dataNamespace.com"
          xmlns:lol1="http://refNamespace.com"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <op3>
            <lol0:DataElem>
              <data1>64</data1>
              <data2>128</data2>
            </lol0:DataElem>
            <in2>
              <lol1:RefDataElem>3</lol1:RefDataElem>
            </in2>
          </op3>
        </env:Body>
      </env:Envelope>
    ')

    expect(actual).to be_equivalent_to(expected).respecting_element_order
  end

end
