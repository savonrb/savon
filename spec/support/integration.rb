module SpecSupport

  def call_and_fail_gracefully(client, *args, &block)
    client.call(*args, &block)
  rescue Savon::SOAPFault => e
    puts e.message
  end

end
