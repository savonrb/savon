class Hash

  # Expects an Array of Regexp Objects of which every Regexp recursively
  # matches a key to be accessed. Returns the value of the last Regexp filter
  # found in the Hash or an empty Hash in case the path of Regexp filters
  # did not match the Hash structure.
  def find_regexp(regexp)
    regexp = [regexp] unless regexp.kind_of? Array
    result = dup

    regexp.each do |pattern|
      result_key = result.keys.find { |key| key.to_s.match pattern }
      result = result[result_key] ? result[result_key] : {}
    end
    result
  end

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
    if keys.include? "faultcode"
      "(#{self['faultcode']}) #{self['faultstring']}"
    elsif keys.include? "code"
      "(#{self['code']['value']}) #{self['reason']['text']}"
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
