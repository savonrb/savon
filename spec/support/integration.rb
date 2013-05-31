module SpecSupport

  def fail_gracefully
    yield
  rescue Savon::SOAPFault => e
    pending e.message
  end

end
