module Savon

  # = Savon::SOAP
  #
  # Contains various SOAP details.
  module SOAP

    # Default SOAP version.
    DEFAULT_VERSION = 1

    # Supported SOAP versions.
    VERSIONS = 1..2

    # SOAP namespaces by SOAP version.
    NAMESPACE = {
      1 => "http://schemas.xmlsoap.org/soap/envelope/",
      2 => "http://www.w3.org/2003/05/soap-envelope"
    }

  end
end
