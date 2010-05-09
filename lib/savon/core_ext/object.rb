class Object

  # Returns +true+ if the Object is nil, false or empty. Implementation from ActiveSupport.
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end unless defined? blank?

  # Returns the Object as a SOAP request compliant value.
  def to_soap_value
    return to_s unless respond_to? :to_datetime
    to_datetime.to_soap_value
  end

  alias_method :to_soap_value!, :to_soap_value

end
