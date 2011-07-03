require "wasabi/version"
require "wasabi/document"

module Wasabi

  # Expects a WSDL document and returns a <tt>Wasabi::Document</tt>.
  def self.document(document)
    Document.new(document)
  end

end
