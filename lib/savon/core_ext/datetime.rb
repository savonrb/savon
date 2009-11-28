class DateTime

  # Returns the DateTime as an xs:dateTime formatted String.
  def to_soap_value
    strftime soap_datetime_format
  end

end
