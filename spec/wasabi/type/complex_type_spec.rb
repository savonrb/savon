require 'spec_helper'

describe Wasabi::Type::ComplexType do

  specify 'all/element' do
    complex_type = new_complex_type('
      <xs:complexType name="MpUser" xmlns="http://www.w3.org/2001/XMLSchema">
        <xs:all>
          <xs:element name="speciality" type="xs:string"/>
          <xs:element name="firstname" type="xs:string"/>
          <xs:element name="lastname" type="xs:string"/>
          <xs:element name="login" type="xs:string"/>
        </xs:all>
      </xs:complexType>
    ')

    expect(complex_type).to be_a(Wasabi::Type::ComplexType)

    all = complex_type.children.first
    expect(all).to be_a(Wasabi::Type::All)

    elements = all.children
    expect(elements.count).to eq(4)

    elements.each do |element|
      expect(element).to be_a(Wasabi::Type::Element)
    end

    element_names = elements.map(&:name)
    expect(element_names).to eq(%w[speciality firstname lastname login])

    expect(complex_type.child_elements).to eq(elements)
  end

  specify 'complexContent/extension/sequence/element' do
    base_type = new_complex_type('
      <complexType name="baseObject">
        <sequence>
          <element minOccurs="0" maxOccurs="unbounded" name="ExemptState" nillable="true" type="tns:ExemptState" />
        </sequence>
      </complexType>
    ')

    # mock the schemas for #child_elements
    schemas = mock('schemas')
    schemas.expects(:complex_type).with('http://example.com/ons', 'baseObject').returns(base_type)

    complex_type = new_complex_type('
			<complexType name="Account" xmlns="http://www.w3.org/2001/XMLSchema"
                                  xmlns:ons="http://example.com/ons"
                                  xmlns:ens="http://example.com/ens">
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
    ', schemas)

    expect(complex_type).to be_a(Wasabi::Type::ComplexType)

    complex_content = complex_type.children.first
    expect(complex_content).to be_a(Wasabi::Type::ComplexContent)

    extension = complex_content.children.first
    expect(extension).to be_a(Wasabi::Type::Extension)

    expect(extension['base']).to eq('ons:baseObject')

    sequence = extension.children.first
    expect(sequence).to be_a(Wasabi::Type::Sequence)

    sequence_elements = sequence.children
    expect(sequence_elements.count).to eq(3)

    expect(sequence_elements[0]).to be_a(Wasabi::Type::Element)
    expect(sequence_elements[0].name).to eq('Description')

    expect(sequence_elements[1]).to be_a(Wasabi::Type::Element)
    expect(sequence_elements[1].name).to eq('ProcessId')

    expect(sequence_elements[1].type).to eq('ens:ID')
    expect(sequence_elements[1].namespaces).to include('xmlns:ens' => 'http://example.com/ens')

    expect(sequence_elements[2]).to be_a(Wasabi::Type::Element)
    expect(sequence_elements[2].name).to eq('CreatedDate')

    # complex_type#child_elements resolves extensions
    extension_elements = [base_type]
    all_elements = extension_elements + sequence_elements

    expect(complex_type.child_elements).to eq(all_elements)
  end

  specify 'complexType/simpleContent/attribute (plus annotations)' do
    complex_type = new_complex_type('
      <xs:complexType name="MeasureType">
        <xs:annotation>
          <xs:documentation>
            Basic type for specifying measures and the system of measurement.
          </xs:documentation>
        </xs:annotation>
        <xs:simpleContent>
          <xs:extension base="xs:decimal">
            <xs:attribute name="unit" type="xs:token" use="optional">
              <xs:annotation>
                <xs:documentation>
                  Unit of measure. This attribute is shared by various fields,
                  representing units such as lbs, oz, kg, g, in, cm.
                </xs:documentation>
                <xs:appinfo>
                  <CallInfo>
                    <CallName>AddItem</CallName>
                    <CallName>AddItems</CallName>
                    <RequiredInput>No</RequiredInput>
                  </CallInfo>
                  <CallInfo>
                    <CallName>GetItemShipping</CallName>
                    <CallName>GetSellerTransactions</CallName>
                    <CallName>GetShippingDiscountProfiles</CallName>
                    <Returned>Conditionally</Returned>
                  </CallInfo>
                  <CallInfo>
                    <CallName>GetItem</CallName>
                    <Details>DetailLevel: none, ItemReturnDescription, ItemReturnAttributes, ReturnAll</Details>
                    <Returned>Conditionally</Returned>
                  </CallInfo>
                </xs:appinfo>
              </xs:annotation>
            </xs:attribute>
          </xs:extension>
        </xs:simpleContent>
      </xs:complexType>
    ')

    expect(complex_type).to be_a(Wasabi::Type::ComplexType)
    expect(complex_type.child_elements).to be_empty
  end

  specify 'complexType/sequence/element/simpleType' do
    complex_type = new_complex_type('
      <xsd:complexType name="JobStats">
        <xsd:sequence>
          <xsd:element name="jobID" type="xsd:integer"/>
          <xsd:element name="jobType" type="xsd:string"/>
          <xsd:element name="jobState">
            <xsd:simpleType>
              <xsd:restriction base="xsd:string">
                <xsd:enumeration value="Running"/>
                <xsd:enumeration value="Finished"/>
                <xsd:enumeration value="Error"/>
                <xsd:enumeration value="Queued"/>
                <xsd:enumeration value="Cancelled"/>
              </xsd:restriction>
            </xsd:simpleType>
          </xsd:element>
        </xsd:sequence>
      </xsd:complexType>
    ')

    expect(complex_type).to be_a(Wasabi::Type::ComplexType)

    elements = complex_type.child_elements
    expect(elements.count).to eq(3)

    expect(elements[0].type).to eq('xsd:integer')
    expect(elements[1].type).to eq('xsd:string')
    expect(elements[2].type).to eq('xsd:string')
  end

  specify 'complexType/sequence' do
    complex_type = new_complex_type('
      <xs:complexType name="paypal">
        <xs:sequence/>
      </xs:complexType>
    ')

    expect(complex_type).to be_a(Wasabi::Type::ComplexType)
    expect(complex_type).to be_empty
  end

  def new_complex_type(xml, schemas = nil)
    node = Nokogiri.XML(xml).root
    schemas ||= mock('schemas')
    schema = {}

    Wasabi::Type::ComplexType.new(node, schemas, schema)
  end

end
