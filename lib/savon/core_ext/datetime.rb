class DateTime

  # Return the DateTime as a xs:dateTime formatted String.
  def to_soap_value
    strftime soap_datetime_format
  end

end