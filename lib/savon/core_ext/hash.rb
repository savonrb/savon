class Hash

  # Returns the Hash translated into SOAP request compatible XML.
  #
  # === Example
  #
  #   { :find_user => { :id => 666 } }.to_soap_xml
  #   => "<findUser><id>666</id></findUser>"
  def to_soap_xml
    @soap_xml = Builder::XmlMarkup.new
    each { |key, value| nested_data_to_soap_xml key, value }
    @soap_xml.target!
  end

  # Tries to generate a SOAP fault message from the Hash. Returns nil in
  # case no SOAP fault could be found or generated.
  def to_soap_fault_message
    soap_fault = self["soap:Envelope"]["soap:Body"]["soap:Fault"] rescue {}
    return nil unless soap_fault

    if soap_fault.keys.include? "faultcode"
      "(#{soap_fault['faultcode']}) #{soap_fault['faultstring']}"
    elsif soap_fault.keys.include? "code"
      "(#{soap_fault['code']['value']}) #{soap_fault['reason']['text']}"
    else
      nil
    end
  end

  # Maps keys and values of a Hash created from SOAP response XML to
  # more convenient Ruby Objects.
  def map_soap_response
    inject({}) do |hash, (key, value)|
      key = key.strip_namespace.snakecase.to_sym

      value = case value
        when Hash
          value["xsi:nil"] ? nil : value.map_soap_response
        when Array
          value.map { |a_value| a_value.map_soap_response rescue a_value }
        when String
          value.map_soap_response
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
