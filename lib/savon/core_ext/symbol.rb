class Symbol

  # Returns the Symbol as a lowerCamelCase String.
  def to_soap_key
    to_s.lower_camelcase
  end

end