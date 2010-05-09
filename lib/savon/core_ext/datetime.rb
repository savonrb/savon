class DateTime

  # Returns the DateTime as an xs:dateTime formatted String.
  def to_soap_value
    strftime Savon::SOAP::DateTimeFormat
  end

  alias_method :to_soap_value!, :to_soap_value

end
