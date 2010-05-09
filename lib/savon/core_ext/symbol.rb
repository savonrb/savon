class Symbol

  # Returns the Symbol as a lowerCamelCase String.
  def to_soap_key
    to_s.to_soap_key.lower_camelcase
  end

end