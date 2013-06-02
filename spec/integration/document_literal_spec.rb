require 'spec_helper'

describe 'Integration with a Document/Literal example' do

  subject(:client) { Savon.new fixture('wsdl/document_literal_wrapped') }

  let(:service_name) { :SampleService }
  let(:port_name)    { :Sample }

  it 'works with op1' do
    op1 = client.operation(service_name, port_name, :op1)

    expect(op1.example_body).to eq(
      op1: {
        in: {
          data1: 'int',
          data2: 'int'
        }
      }
    )

    op1.body = {
      op1: {
        in: {
          data1: 24,
          data2: 36
        }
      }
    }

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

    expect(Nokogiri.XML op1.build).
      to be_equivalent_to(expected).respecting_element_order
  end

  it 'works with op3' do
    op3 = client.operation(service_name, port_name, :op3)

    expect(op3.example_body).to eq(
      op3: {
        DataElem: {
          data1: 'int',
          data2: 'int'
        },
        in2: {
          RefDataElem: 'int'
        }
      }
    )

    op3.body = {
      op3: {
        DataElem: {
          data1: 64,
          data2: 128
        },
        in2: {
          RefDataElem: 3
        }
      }
    }

    expected = Nokogiri.XML('
      <env:Envelope
          xmlns:lol0="http://apiNamespace.com"
          xmlns:lol1="http://dataNamespace.com"
          xmlns:lol2="http://refNamespace.com"
          xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
        <env:Header/>
        <env:Body>
          <lol0:op3>
            <lol1:DataElem>
              <data1>64</data1>
              <data2>128</data2>
            </lol1:DataElem>
            <in2>
              <lol2:RefDataElem>3</lol2:RefDataElem>
            </in2>
          </lol0:op3>
        </env:Body>
      </env:Envelope>
    ')

    expect(Nokogiri.XML op3.build).
      to be_equivalent_to(expected).respecting_element_order
  end

end
