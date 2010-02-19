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
  # === Example:
  #
  #   { :find_user => { :id => 123, "wsdl:Key" => "api" } }.to_soap_xml
  #   # => "<findUser><id>123</id><wsdl:Key>api</wsdl:Key></findUser>"
  #
  # Comes with a way to control the order of XML tags in case you're foced to do so (parameterOrder).
  # Specify an optional Array under the :order! key reflecting the order of your keys.
  # An ArgumentError is raised unless the Array contains the exact same/all keys of your Hash.
  #
  # === Example:
  #
  #   { :find_user => { :name => "Eve", :id => 123, :order! => [:id, :name] } }.to_soap_xml
  #   # => "<findUser><id>123</id><name>Eve</name></findUser>"
  #
  # You can also specify attributes for XML tags by via an optional Hash under the :attributes! key.
  #
  # === Example:
  #
  #   { :find_user => { :person => "Eve", :attributes! => { :person => { :id => 123 } } } }
  #   # => "<findUser><person id="123">Eve</person></findUser>"
  def to_soap_xml
    xml = Builder::XmlMarkup.new
    attributes = delete(:attributes!) || {}

    order.each do |key|
      attrs = attributes[key] || {}
      value = self[key]
      key = key.to_soap_key

      case value
        when Array then xml << value.to_soap_xml(key)
        when Hash  then xml.tag!(key, attrs) { xml << value.to_soap_xml }
        else            xml.tag!(key, attrs) { xml << value.to_soap_value }
      end
    end

    xml.target!
  end

  # Maps keys and values of a Hash created from SOAP response XML to more convenient Ruby Objects.
  def map_soap_response
    inject({}) do |hash, (key, value)|
      value = case value
        when Hash   then value["xsi:nil"] ? nil : value.map_soap_response
        when Array  then value.map { |a_value| a_value.map_soap_response rescue a_value }
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
