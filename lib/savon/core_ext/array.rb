class Array

  # Translates the Array into SOAP compatible XML. See: Hash.to_soap_xml.
  def to_soap_xml(key)
    xml = Builder::XmlMarkup.new

    each do |item|
      case item
        when Array, Hash then xml.tag!(key) { xml << item.to_soap_xml }
        else                  xml.tag!(key) { xml << item.to_soap_value }
      end
    end

    xml.target!
  end

end
