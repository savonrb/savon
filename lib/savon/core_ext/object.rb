class Object

  # Returns the Object as a SOAP request compliant key.
  def to_soap_key
    to_s
  end

  # Returns the Object as a SOAP request compliant value.
  def to_soap_value
    return to_s unless respond_to? :to_datetime
    to_datetime.to_soap_value
  end

private

  # The xs:dateTime format.
  def soap_datetime_format
    Savon::SOAPDateTimeFormat
  end

end
