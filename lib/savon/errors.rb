class Savon

  # Public: Base error class.
  Error = Class.new(RuntimeError)

  # Public: Raised if the style of an operation is not supported.
  UnsupportedStyleError = Class.new(Error)

end
