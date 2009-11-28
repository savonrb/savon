class String

  # Returns the String in snake_case.
  def snakecase
    str = dup
    str.gsub! /::/, '/'
    str.gsub! /([A-Z]+)([A-Z][a-z])/, '\1_\2'
    str.gsub! /([a-z\d])([A-Z])/, '\1_\2'
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

  # Returns the String without namespace.
  def strip_namespace
    gsub /(.+:)(.+)/, '\2'
  end

  # Returns the String as a SOAP request compliant value.
  def to_soap_value
    to_s
  end

end