class Hash

  # Returns the values from the soap:Body element or an empty Hash in case the soap:Body tag could
  # not be found.
  def find_soap_body
    envelope = self[keys.first] || {}
    body_key = envelope.keys.find { |key| /.+:Body/ =~ key } rescue nil
    body_key ? envelope[body_key].map_soap_response : {}
  end

  # Translates the Hash into SOAP request compatible XML.
  #
  #   { :find_user => { :id => 123, "wsdl:Key" => "api" } }.to_soap_xml
  #   # => "<findUser><id>123</id><wsdl:Key>api</wsdl:Key></findUser>"
  #
  # ==== Mapping
  #
  # * Hash keys specified as Symbols are converted to lowerCamelCase Strings
  # * Hash keys specified as Strings are not converted and may contain namespaces
  # * DateTime values are converted to xs:dateTime Strings
  # * Objects responding to to_datetime (except Strings) are converted to xs:dateTime Strings
  # * TrueClass and FalseClass objects are converted to "true" and "false" Strings
  # * All other objects are expected to be converted to Strings using to_s
  #
  # An example:
  #
  #   { :magic_request => {
  #       :perform_move => true,
  #       "perform_at" => DateTime.new(2010, 11, 22, 11, 22, 33)
  #     }
  #   }.to_soap_xml
  #
  #   <magicRequest>
  #     <performMove>true</performMove>
  #     <perform_at>2012-06-11T10:42:21</perform_at>
  #   </magicRequest>
  #
  # ==== Escaped XML values
  #
  # By default, special characters in XML String values are escaped.
  #
  # ==== Fixed order of XML tags
  #
  # In case your service requires the tags to be in a specific order (parameterOrder), you have two
  # options. The first is to specify your body as an XML string. The second is to specify the order
  # through an additional array stored under the +:order!+ key.
  #
  #   { :name => "Eve", :id => 123, :order! => [:id, :name] }.to_soap_xml
  #   # => "<id>123</id><name>Eve</name>"
  #
  # ==== XML attributes
  #
  # If you need attributes, you could either go with an XML string or add another hash under the
  # +:attributes!+ key.
  #
  #   { :person => "Eve", :attributes! => { :person => { :id => 666 } } }.to_soap_xml
  #   # => '<person id="666">Eve</person>'
  def to_soap_xml
    xml = Builder::XmlMarkup.new
    attributes = delete(:attributes!) || {}

    order.each do |key|
      attrs = attributes[key] || {}
      value = self[key]
      escape_xml = key.to_s[-1, 1] != "!"
      key = key.to_soap_key

      case value
        when Array then xml << value.to_soap_xml(key, escape_xml, attrs)
        when Hash  then xml.tag!(key, attrs) { xml << value.to_soap_xml }
        else            xml.tag!(key, attrs) { xml << (escape_xml ? value.to_soap_value : value.to_soap_value!) }
      end
    end

    xml.target!
  end

  # Maps keys and values of a Hash created from SOAP response XML to more convenient Ruby Objects.
  def map_soap_response
    inject({}) do |hash, (key, value)|
      value = case value
        when Hash   then value["xsi:nil"] ? nil : value.map_soap_response
        when Array  then value.map { |val| val.map_soap_response rescue val }
        when String then value.map_soap_response
      end

      hash.merge key.strip_namespace.snakecase.to_sym => value
    end
  end

private

  # Deletes and returns an Array of keys stored under the :order! key. Defaults to return the actual
  # keys of this Hash if no :order! key could be found. Raises an ArgumentError in case the :order!
  # Array does not match the Hash keys.
  def order
    order = delete :order!
    order = keys unless order.kind_of? Array

    missing, spurious = keys - order, order - keys
    raise ArgumentError, "Missing elements in :order! #{missing.inspect}" unless missing.empty?
    raise ArgumentError, "Spurious elements in :order! #{spurious.inspect}" unless spurious.empty?

    order
  end

end