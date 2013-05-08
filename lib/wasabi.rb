require "wasabi/version"
require "wasabi/document"
require "wasabi/resolver"

class Wasabi

  XSD      = "http://www.w3.org/2001/XMLSchema"
  WSDL     = "http://schemas.xmlsoap.org/wsdl/"
  SOAP_1_1 = "http://schemas.xmlsoap.org/wsdl/soap/"
  SOAP_1_2 = "http://schemas.xmlsoap.org/wsdl/soap12/"

  # Expects a WSDL document and returns a <tt>Wasabi::Document</tt>.
  def self.document(document)
    Document.new(document)
  end

end
