class Array

  # Translates the Array into SOAP compatible XML. See: Hash.to_soap_xml.
  def to_soap_xml(key, attributes = {})
    xml = Builder::XmlMarkup.new

    each_with_index do |item, index|
      attrs = tag_attributes attributes, index
      case item
        when Hash then xml.tag!(key, attrs) { xml << item.to_soap_xml }
        else           xml.tag!(key, attrs) { xml << item.to_soap_value }
      end
    end

    xml.target!
  end

private

  def tag_attributes(attributes, index)
    return {} if attributes.empty?

    attributes.inject({}) do |hash, (key, value)|
      value = value[index] if value.kind_of? Array
      hash.merge key => value
    end
  end

end