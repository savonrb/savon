class Hash

  # Error message for missing :@inorder elements.
  InOrderMissing = "Missing elements in :@inorder %s"

  # Error message for spurious :@inorder elements.
  InOrderSpurious = "Spurious elements in :@inorder %s"

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
  # To control the order of output, add a key of :@inorder with
  # the value being an Array listing keys in order.
  #
  # === Examples
  #
  #   { :find_user => { :id => 666 } }.to_soap_xml
  #   => "<findUser><id>666</id></findUser>"
  #
  #   { :find_user => { :name => "Lucy", :id => 666, :@inorder => [:id, :name] } }.to_soap_xml
  #   => "<findUser><id>666</id><name>Lucy</name></findUser>"
  def to_soap_xml
    @soap_xml = Builder::XmlMarkup.new
    inorder(self).each { |key| nested_data_to_soap_xml key, self[key] }
    @soap_xml.target!
  end

  # Maps keys and values of a Hash created from SOAP response XML to
  # more convenient Ruby Objects.
  def map_soap_response
    inject({}) do |hash, (key, value)|
      key = key.strip_namespace.snakecase.to_sym

      value = case value
        when Hash   then value["xsi:nil"] ? nil : value.map_soap_response
        when Array  then value.map { |a_value| a_value.map_soap_response rescue a_value }
        when String then value.map_soap_response
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
        value.map { |subitem| nested_data_to_soap_xml key, subitem }
      when Hash
        @soap_xml.tag!(key.to_soap_key) do
          inorder(value).each { |subkey| nested_data_to_soap_xml subkey, value[subkey] }
        end
      else
        @soap_xml.tag!(key.to_soap_key) { @soap_xml << value.to_soap_value }
    end
  end

  # Takes a +hash+, removes the :@inorder marker and returns its keys.
  # Raises an error in case an :@inorder Array does not match the Hash keys.
  def inorder(hash)
    inorder = hash.delete :@inorder
    hash_keys = hash.keys
    inorder = hash_keys unless inorder.kind_of? Array
    raise InOrderMissing % (hash_keys - inorder).inspect unless (hash_keys - inorder).empty?
    raise InOrderSpurious % (inorder - hash_keys).inspect unless (inorder - hash_keys).empty?
    inorder
  end

end
