class Object

  # Returns +true+ if the Object is false, empty, or a whitespace string.
  # For example, "", false, nil, [], and {} are blank.
  # Implementation from ActiveSupport.
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end unless defined? blank?

  # Returns the Object as a SOAP request compliant key.
  def to_soap_key
    to_s
  end

  # Returns the Object as a SOAP request compliant value.
  def to_soap_value
    return to_s unless respond_to? :to_datetime
    to_datetime.to_soap_value
  end

end
