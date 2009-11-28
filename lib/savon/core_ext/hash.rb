class Hash

  # Returns the Hash as SOAP request compatible XML.
  #
  # === Example
  #
  #   { :person_request => { :id => 666 } }.to_soap_xml
  #   => "<personRequest><id>666</id></personRequest>"
  def to_soap_xml
    @soap_xml ||= Builder::XmlMarkup.new
    each { |key, value| nested_data_to_soap_xml key, value }
    @soap_xml.target!
  end

  def map_soap_response
    inject({}) do |hash, (key, value)|
      key = key.strip_namespace.snakecase.to_sym

      value = case value
        when Hash
          value["xsi:nil"] ? nil : value.map_soap_response
        when Array
          value.map { |a_value| a_value.map_soap_response rescue a_value }
        else
          value
      end
      hash.merge key => value
    end
  end

private

  # Expects a Hash +key+ and +value+ and recursively creates an XML structure
  # representing the Hash content.
  def nested_data_to_soap_xml(key, value)
    case value
      when Array
        value.map { |sitem| nested_data_to_soap_xml key, sitem }
      when Hash
        @soap_xml.tag!(key.to_soap_key) do
          value.each { |subkey, subvalue| nested_data_to_soap_xml subkey, subvalue }
        end
      else
        @soap_xml.tag!(key.to_soap_key) { @soap_xml << value.to_soap_value }
    end
  end

end