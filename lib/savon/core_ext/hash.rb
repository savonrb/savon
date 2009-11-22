class Hash

  def soap_request_mapping
    dup.inject({}) do |result, (key, value)|
      result[soap_compatible_key(key)] = map_soap_request_value value
      result
    end
  end

  def soap_response_mapping
    dup.inject({}) do |result, (key, value)|
      result[key] = map_soap_response_value value
      result
    end
  end

private

  def soap_compatible_key(key)
    key.kind_of?(Symbol) ? key.to_s.lower_camelcase : key.to_s
  end

  def map_soap_request_value(value)
    case value
      when Hash  then value.soap_request_mapping
      when Array then value.map { |single| map_soap_request_value single }
                 else translate_soap_request_value value
    end
  end

  def translate_soap_request_value(value)
    if value.kind_of? DateTime
      value.strftime Savon::SOAPDateTimeFormat
    elsif !value.kind_of?(String) && value.respond_to?(:to_datetime)
      value.to_datetime.strftime Savon::SOAPDateTimeFormat
    elsif value.respond_to? :to_s
      value.to_s
    else
      nil
    end
  end

  def map_soap_response_value(value)
    case value
      when Hash  then value.soap_response_mapping
      when Array then value.map { |single| map_soap_response_value single }
                 else translate_soap_response_value value
    end
  end

  def translate_soap_response_value(value)
    case value
      when Savon::SOAPDateTimeRegexp then DateTime.parse value
      when "true"                    then true
      when "false"                   then false
                                     else value
    end
  end

end