class Savon

  Error                 = Class.new(RuntimeError)
  InitializationError   = Class.new(Error)
  UnknownOptionError    = Class.new(Error)
  UnknownOperationError = Class.new(Error)
  InvalidResponseError  = Class.new(Error)

end
