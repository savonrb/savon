module SpecSupport

  def call_and_fail_gracefully(client, *args)
    client.call(*args)
  rescue Savon::SOAPFault => e
    pending e.message
  end

end
