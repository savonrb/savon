module Savon

  # == Savon::SOAP
  #
  # Represents the SOAP parameters and envelope.
  class SOAP

    # SOAP namespaces by SOAP version.
    SOAPNamespace = {
      1 => "http://schemas.xmlsoap.org/soap/envelope/",
      2 => "http://www.w3.org/2003/05/soap-envelope"
    }

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    # The global SOAP version.
    @@version = 1

    # Returns the global SOAP version.
    def self.version
      @@version
    end

    # Sets the global SOAP version.
    def self.version=(version)
      @@version = version if Savon::SOAPVersions.include? version
    end

    # Sets the global SOAP header. Expected to be a Hash that can be translated
    # to XML via Hash.to_soap_xml or any other Object responding to to_s.
    def self.header=(header)
      @@header = header
    end

    # Returns the global SOAP header. Defaults to an empty Hash.
    def self.header
      @@header ||= {}
    end

    # Sets the global namespaces. Expected to be a Hash containing the
    # namespaces (keys) and the corresponding URI's (values).
    def self.namespaces=(namespaces)
      @@namespaces = namespaces if namespaces.kind_of? Hash
    end

    # Returns the global namespaces. A Hash containing the namespaces (keys)
    # and the corresponding URI's (values).
    def self.namespaces
      @@namespaces ||= {}
    end

    # Initialzes the SOAP object.
    def initialize
      @builder = Builder::XmlMarkup.new
    end

    # Sets the WSSE options.
    attr_writer :wsse

    # Sets the SOAP action.
    attr_writer :action

    # Returns the SOAP action.
    def action
      @action ||= ""
    end

    # Sets the SOAP input.
    attr_writer :input

    # Returns the SOAP input.
    def input
      @input ||= ""
    end

    # Accessor for the SOAP endpoint.
    attr_accessor :endpoint

    # Sets the SOAP header. Expected to be a Hash that can be translated
    # to XML via Hash.to_soap_xml or any other Object responding to to_s.
    attr_writer :header

    # Returns the SOAP header. Defaults to an empty Hash.
    def header
      @header ||= {}
    end

    # Sets the SOAP body. Expected to be a Hash that can be translated to
    # XML via Hash.to_soap_xml or any other Object responding to to_s.
    attr_writer :body

    # Sets the namespaces. Expected to be a Hash containing the namespaces
    # (keys) and the corresponding URI's (values).
    attr_writer :namespaces

    # Returns the namespaces. A Hash containing the namespaces (keys)
    # and the corresponding URI's (values).
    def namespaces
      @namespaces ||= { "xmlns:env" => SOAPNamespace[version] }
    end

    # Convenience method for setting the "xmlns:wsdl" namespace.
    def namespace=(namespace)
      namespaces["xmlns:wsdl"] = namespace
    end

    # Sets the SOAP version.
    def version=(version)
      @version = version if Savon::SOAPVersions.include? version
    end

    # Returns the SOAP version. Defaults to the global default.
    def version
      @version ||= self.class.version
    end

    # Returns the SOAP envelope XML.
    def to_xml
      unless @xml_body
        @xml_body = @builder.env :Envelope, all_namespaces do |xml|
          xml.env(:Header) { xml << all_header } unless all_header.empty?
          xml_body xml
        end
      end
      @xml_body
    end

  private

    # Returns a String containing the global and per request header.
    def all_header
      if self.class.header.kind_of?(Hash) && header.kind_of?(Hash)
        custom_header = self.class.header.merge(header).to_soap_xml
      else
        custom_header = self.class.header.to_s + header.to_s
      end
      custom_header + wsse_header
    end

    # Returns the WSSE header or an empty String in case WSSE was not set.
    def wsse_header
      @wsse.respond_to?(:header) ? @wsse.header : ""
    end

    # Adds a SOAP XML body to a given +xml+ Object.
    def xml_body(xml)
      xml.env(:Body) do
        xml.tag!(:wsdl, *input_array) do
          xml << (@body.to_soap_xml rescue @body.to_s)
        end
      end
    end

    # Returns a Hash containing the global and per request namespaces.
    def all_namespaces
      self.class.namespaces.merge namespaces
    end

    # Returns an Array of SOAP input names to append to the :wsdl namespace.
    # Defaults to use the name of the SOAP action and may be an empty Array
    # in case the specified SOAP input seems invalid.
    def input_array
      return input.map { |i| i.is_a?(Hash) ? i : i.to_sym } unless input.blank?
      return [action.to_sym] unless action.blank?
      []
    end

  end
end
