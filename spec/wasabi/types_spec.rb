require 'spec_helper'

describe Wasabi::Parser do

  it 'knows xs:all types' do
    parser = parse('
      <definitions name="Api" targetNamespace="urn:ActionWebService"
          xmlns="http://schemas.xmlsoap.org/wsdl/"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema">
        <types>
          <xsd:schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:ActionWebService">
            <xsd:complexType name="MpUser">
              <xsd:all>
                <xsd:element name="avatar_thumb_url" type="xsd:string"/>
                <xsd:element name="speciality" type="xsd:string"/>
                <xsd:element name="avatar_icon_url" type="xsd:string"/>
                <xsd:element name="firstname" type="xsd:string"/>
                <xsd:element name="city" type="xsd:string"/>
                <xsd:element name="mp_id" type="xsd:int"/>
                <xsd:element name="lastname" type="xsd:string"/>
                <xsd:element name="login" type="xsd:string"/>
              </xsd:all>
            </xsd:complexType>
          </xsd:schema>
        </types>
      </definitions>
    ')

    expect(parser.complex_types).to include('MpUser')
    mp_user = parser.complex_types['MpUser']

    expect(mp_user).to be_a(Wasabi::Type)
    expect(mp_user.children).to eq([
      { :name => 'avatar_thumb_url', :type => 'xsd:string' },
      { :name => 'speciality',       :type => 'xsd:string' },
      { :name => 'avatar_icon_url',  :type => 'xsd:string' },
      { :name => 'firstname',        :type => 'xsd:string' },
      { :name => 'city',             :type => 'xsd:string' },
      { :name => 'mp_id',            :type => 'xsd:int'    },
      { :name => 'lastname',         :type => 'xsd:string' },
      { :name => 'login',            :type => 'xsd:string' }
    ])
  end

  def parse(xml)
    parser = Wasabi::Parser.new Nokogiri.XML(xml)
    parser.parse
    parser
  end

end
