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
  end

  specify 'complexContent/extension/sequence/element' do
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
    ')

    expect(complex_type).to be_a(Wasabi::Type::ComplexType)

    complex_content = complex_type.children.first
    expect(complex_content).to be_a(Wasabi::Type::ComplexContent)

    extension = complex_content.children.first
    expect(extension).to be_a(Wasabi::Type::Extension)

    expect(extension['base']).to eq('ons:baseObject')

    sequence = extension.children.first
    expect(sequence).to be_a(Wasabi::Type::Sequence)

    elements = sequence.children
    expect(elements.count).to eq(3)

    expect(elements[0]).to be_a(Wasabi::Type::Element)
    expect(elements[0].name).to eq('Description')

    expect(elements[1]).to be_a(Wasabi::Type::Element)
    expect(elements[1].name).to eq('ProcessId')

    expect(elements[1]['type']).to eq('ens:ID')
    expect(elements[1].namespaces).to include('xmlns:ens' => 'http://example.com/ens')

    expect(elements[2]).to be_a(Wasabi::Type::Element)
    expect(elements[2].name).to eq('CreatedDate')
  end

  def new_complex_type(xml)
    Wasabi::Type::ComplexType.new Nokogiri.XML(xml).root
  end

end
