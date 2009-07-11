class WsdlFactory
  attr_accessor :namespace_uri, :service_methods, :choice_elements

  def initialize(new_options = {})
    options = {
      :namespace_uri => "http://some.example.com",
      :service_methods => {"findById" => ["id"]},
      :choice_elements => {}
    }.update(new_options)

    @namespace_uri = options[:namespace_uri]
    @service_methods = options[:service_methods]
    @choice_elements = options[:choice_elements]
  end

  def build
    wsdl = '<wsdl:definitions name="SomeService" targetNamespace="' << namespace_uri << '"
      xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:tns="http://example.com"
      xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
      <wsdl:types>
        <xs:schema attributeFormDefault="unqualified" elementFormDefault="unqualified"
          targetNamespace="http://example.com" xmlns:tns="http://example.com"
          xmlns:xs="http://www.w3.org/2001/XMLSchema">'
    wsdl << build_elements
    wsdl << '<xs:element name="result" type="tns:result" />'
    wsdl << build_complex_types
    wsdl << '<xs:complexType name="result">
            <xs:sequence><xs:element name="token" type="xs:token" /></xs:sequence>
          </xs:complexType>
        </xs:schema>
      </wsdl:types>'
    wsdl << build_messages
    wsdl << '<wsdl:portType name="SomeWebService">'
    wsdl << build_operation_input_output
    wsdl << '</wsdl:portType>
      <wsdl:binding name="SomeServiceSoapBinding" type="tns:SomeService">
        <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http" />'
    wsdl << build_operation_input_output_body
    wsdl << '</wsdl:binding>
      <wsdl:service name="SomeService">
        <wsdl:port binding="tns:SomeServiceSoapBinding" name="SomeServicePort">
          <soap:address location="http://example.com/SomeService" />
        </wsdl:port>
      </wsdl:service>
    </wsdl:definitions>'
  end

  def build_elements
    wsdl = service_methods.keys.map { |method|
      '<xs:element name="' << method << '" type="tns:' << method << '" />
      <xs:element name="' << method << 'Response" type="tns:' << method << 'Response" />'
    }.to_s
    wsdl << choice_elements.map { |c_method, c_elements|
      c_elements.map { |c_element|
        '<xs:element name="' << c_element << '" type="tns:' << c_element << 'Value" />'
      }.to_s
    }.to_s
    wsdl
  end

  def build_complex_types
    service_methods.map { |method, inputs|
      wsdl = '<xs:complexType name="' << method << '"><xs:sequence>'
      inputs.each do |input|
        if choice_elements.keys.include? input
          wsdl << '<xs:choice>'
          wsdl << choice_elements[input].map { |element|
            '<xs:element ref="tns:' << element << '"/>'
          }.to_s
          wsdl << '</xs:choice>'
        else
          wsdl << '<xs:element minOccurs="0" name="' << input << '" type="xs:string" />'
        end
      end
      wsdl << '</xs:sequence></xs:complexType>'
      wsdl << build_complex_types_choice_elements
      wsdl << '<xs:complexType name="' << method << 'Response"><xs:sequence>
          <xs:element minOccurs="0" name="return" type="tns:result" />
        </xs:sequence></xs:complexType>'
    }.to_s
  end

  def build_complex_types_choice_elements
    choice_elements.map { |c_method, c_elements|
        c_elements.map { |c_element|
          '<xs:complexType name="' << c_element << 'Value"><xs:sequence>
          <xs:element minOccurs="0" name="' << c_element << '" type="xs:string" />
          </xs:sequence></xs:complexType>'
        }.to_s
      }.to_s
  end

  def build_messages
    service_methods.keys.map { |method|
      '<wsdl:message name="' << method << '">
        <wsdl:part element="tns:' << method << '" name="parameters"> </wsdl:part>
      </wsdl:message>
      <wsdl:message name="' << method << 'Response">
        <wsdl:part element="tns:' << method << 'Response" name="parameters"> </wsdl:part>
      </wsdl:message>'
    }.to_s
  end

  def build_operation_input_output
    service_methods.keys.map { |method|
      '<wsdl:operation name="' << method << '">
        <wsdl:input message="tns:' << method << '" name="' << method << '"> </wsdl:input>
        <wsdl:output message="tns:' << method << 'Response" name="' << method << 'Response"> </wsdl:output>
      </wsdl:operation>'
    }.to_s
  end

  def build_operation_input_output_body
    service_methods.keys.map { |method|
      '<wsdl:operation name="' << method << '">
        <soap:operation soapAction="" style="document" />
        <wsdl:input name="' << method << '">
          <soap:body use="literal" />
        </wsdl:input>
        <wsdl:output name="' << method << 'Response">
          <soap:body use="literal" />
        </wsdl:output>
      </wsdl:operation>'
    }.to_s
  end

end