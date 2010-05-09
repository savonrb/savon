class String

  # Returns a random String of a given +length+.
  def self.random(length = 100)
    (0...length).map { ("a".."z").to_a[rand(26)] }.join
  end

  # Returns the String in snake_case.
  def snakecase
    str = dup
    str.gsub! /::/, '/'
    str.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
    str.gsub! /([a-z\d])([A-Z])/, '\1_\2'
    str.tr! ".", "_"
    str.tr! "-", "_"
    str.downcase!
    str
  end

  # Returns the String in lowerCamelCase.
  def lower_camelcase
    str = dup
    str.gsub!(/\/(.?)/) { "::#{$1.upcase}" }
    str.gsub!(/(?:_+|-+)([a-z])/) { $1.upcase }
    str.gsub!(/(\A|\s)([A-Z])/) { $1 + $2.downcase }
    str
  end

  # Returns whether the String starts with a given +prefix+.
  def starts_with?(prefix)
    prefix = prefix.to_s
    self[0, prefix.length] == prefix
  end unless defined? starts_with?

  # Returns whether the String ends with a given +suffix+.
  def ends_with?(suffix)
    suffix = suffix.to_s
    self[-suffix.length, suffix.length] == suffix
  end unless defined? ends_with?

  # Returns the String without namespace.
  def strip_namespace
    split(":").last
  end

  # Translates SOAP response values to Ruby Objects.
  def map_soap_response
    return DateTime.parse(self) if Savon::SOAP::DateTimeRegexp === self
    return true if self.strip.downcase == "true"
    return false if self.strip.downcase == "false"
    self
  end

  # Returns the Object as a SOAP request compliant key.
  def to_soap_key
    self[-1, 1] == "!" ? chop : self
  end

  # Returns the String as a SOAP value. Escapes special characters for XML.
  def to_soap_value
    CGI.escapeHTML self
  end

  # Convert the String into a SOAP value without escaping special characters.
  def to_soap_value!
    self
  end

end
