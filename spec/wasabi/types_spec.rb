require 'spec_helper'

describe Wasabi do

  it 'knows simple types' do
    wsdl = wsdl('
      <xs:schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:ActionWebService">
        <xs:simpleType name="TemperatureUnit">
          <xs:restriction base="xs:string">
            <xs:enumeration value="degreeCelsius" />
            <xs:enumeration value="degreeFahrenheit" />
            <xs:enumeration value="degreeRankine" />
            <xs:enumeration value="degreeReaumur" />
            <xs:enumeration value="kelvin" />
          </xs:restriction>
        </xs:simpleType>
      </xs:schema>
    ')

    unit = wsdl.schemas.simple_type('TemperatureUnit')

    expect(unit).to be_a(Wasabi::Type::SimpleType)
    expect(unit.type).to eq('xs:string')
  end

  it 'knows xs:all types' do
    wsdl = wsdl('
      <xs:schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:ActionWebService">
        <xs:complexType name="MpUser">
          <xs:all>
            <xs:element name="avatar_thumb_url" type="xs:string"/>
            <xs:element name="speciality" type="xs:string"/>
            <xs:element name="avatar_icon_url" type="xs:string"/>
            <xs:element name="firstname" type="xs:string"/>
            <xs:element name="city" type="xs:string"/>
            <xs:element name="mp_id" type="xs:int"/>
            <xs:element name="lastname" type="xs:string"/>
            <xs:element name="login" type="xs:string"/>
          </xs:all>
        </xs:complexType>
      </xs:schema>
    ')

    mp_user = wsdl.schemas.complex_type('MpUser')

    expect(mp_user).to be_a(Wasabi::Type::LegacyType)
    expect(mp_user).to have(8).children

    expect(mp_user.children).to include(
      { :name => 'mp_id',     :type => 'xs:int',    :simple_type => true, :form => nil, :singular => true },
      { :name => 'firstname', :type => 'xs:string', :simple_type => true, :form => nil, :singular => true },
      { :name => 'lastname',  :type => 'xs:string', :simple_type => true, :form => nil, :singular => true },
      { :name => 'login',     :type => 'xs:string', :simple_type => true, :form => nil, :singular => true }
    )
  end

  it 'works with multiple schemas and extensions' do
    wsdl = wsdl('
		<schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="http://object.api.example.com/"
            attributeFormDefault="qualified" elementFormDefault="qualified">
			<complexType name="Account">
				<complexContent>
					<extension base="ons:baseObject">
						<sequence>
							<element minOccurs="0" name="Description" nillable="true" type="string" />
							<element minOccurs="0" name="ProcessId" nillable="true" type="ens:ID" />
              <element minOccurs="0" name="CreatedDate" nillable="true" type="dateTime" />
						</sequence>
					</extension>
				</complexContent>
      </complexType>
			<complexType name="baseObject">
				<sequence>
					<element minOccurs="0" maxOccurs="unbounded" name="fieldsToNull" nillable="true" type="string" />
					<element minOccurs="0" maxOccurs="1" name="Id" nillable="true" type="ens:ID" />
				</sequence>
			</complexType>
    </schema>

		<schema attributeFormDefault="qualified" elementFormDefault="qualified"
            xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="http://api.example.com/">
			<simpleType name="ID">
				<restriction base="xs:string">
					<pattern value="[a-zA-Z0-9]{32}|\d+" />
				</restriction>
			</simpleType>
			<element name="DummyHeader">
				<complexType>
					<sequence>
						<element minOccurs="0" name="Account" nillable="true" type="ons:Account" />
					</sequence>
				</complexType>
      </element>
    </schema>
    ')

    account = wsdl.schemas.complex_type('Account')

    expect(account).to be_a(Wasabi::Type::LegacyType)
    expect(account).to have(5).children

    # TODO: also track whether the elements are nillable like the 'filedToNull' in this example.
    expect(account.children).to eq([
      { :name => 'Description',  :type => 'string',   :simple_type => true,  :form => nil, :singular => true  },
      { :name => 'ProcessId',    :type => 'ens:ID',   :simple_type => false, :form => nil, :singular => true  },
      { :name => 'CreatedDate',  :type => 'dateTime', :simple_type => true,  :form => nil, :singular => true  },
      { :name => 'fieldsToNull', :type => 'string',   :simple_type => true,  :form => nil, :singular => false },
      { :name => 'Id',           :type => 'ens:ID',   :simple_type => false, :form => nil, :singular => true  }
    ])
  end

  it 'determines whether elements are simple types by their namespace' do
    wsdl = wsdl('
      <xs:schema xmlns="http://www.w3.org/2001/XMLSchema" targetNamespace="urn:ActionWebService">
        <xs:element name="TermOfPayment">
          <xs:complexType>
            <xs:sequence>
              <xs:element minOccurs="0" maxOccurs="1" name="termOfPaymentHandle" type="tns:TermOfPaymentHandle" />
              <xs:element minOccurs="1" maxOccurs="1" name="value" nillable="true" type="xs:decimal" />
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:schema>
    ')

    terms = wsdl.schemas.element('TermOfPayment')

    expect(terms).to be_a(Wasabi::Type::LegacyType)
    expect(terms).to have(2).children

    expect(terms.children).to eq([
      {
        :name        => 'termOfPaymentHandle',
        :type        => 'tns:TermOfPaymentHandle',
        :simple_type => false,
        :form        => nil,
        :singular    => true
      },
      {
        :name        => 'value',
        :type        => 'xs:decimal',
        :simple_type => true,
        :form        => nil,
        :singular    => true
      }
    ])
  end

  def wsdl(types)
    wsdl = %'<definitions name="Api" targetNamespace="urn:ActionWebService"
                 xmlns="http://schemas.xmlsoap.org/wsdl/"
                 xmlns:tns="urn:ActionWebService"
                 xmlns:ens="http://api.example.com/"
                 xmlns:ons="http://object.api.example.com/"
                 xmlns:xs="http://www.w3.org/2001/XMLSchema">
               <types>
                 #{types}
               </types>
             </definitions>'

    Wasabi.new(wsdl)
  end

end
