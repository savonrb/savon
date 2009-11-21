class String

  # Converts the Stringto snake_case.
  def snakecase
    gsub(/::/, '/').
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
    gsub(/([a-z\d])([A-Z])/, '\1_\2').
    tr("-", "_").
    downcase
  end

  def lower_camelcase
    str = dup
    str.gsub!(/\/(.?)/){ "::#{$1.upcase}" }
    str.gsub!(/(?:_+|-+)([a-z])/){ $1.upcase }
    str.gsub!(/(\A|\s)([A-Z])/){ $1 + $2.downcase }
    str
  end

end
