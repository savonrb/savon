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

    # The default SOAP version.
    @version = 1

    class << self

      # Returns the default SOAP version.
      attr_reader :version

      # Sets the default SOAP version.
      def version=(version)
        @version = version if Savon::SOAPVersions.include? version
      end

    end

    # Expects a Hash containing the name of the SOAP action and input.
    def initialize(action = nil)
      @action = action.kind_of?(Hash) ? action[:name] : ""
      @input = action.kind_of?(Hash) ? action[:input] : ""
    end

    # Sets the WSSE options.
    attr_writer :wsse

    # Accessor for the SOAP action.
    attr_accessor :action

    # Accessor for the SOAP input.
    attr_writer :input

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

    # Returns the namespaces. A Hash containing the namespaces (keys) and
    # the corresponding URI's (values).
    def namespaces
      @namespaces ||= { "xmlns:env" => SOAPNamespace[version] }
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
        builder = Builder::XmlMarkup.new

        @xml_body = builder.env :Envelope, namespaces do |xml|
          xml.env(:Header) do
            xml << (header.to_soap_xml rescue header.to_s) + wsse_header
          end
          xml.env(:Body) do
            xml.tag!(:wsdl, *input_array) do
              xml << (@body.to_soap_xml rescue @body.to_s)
            end
          end
        end
      end
      @xml_body
    end

  private

    # Returns an Array of SOAP input names to append to the :wsdl namespace.
    # Defaults to use the name of the SOAP action and may be an empty Array
    # in case the specified SOAP input seems invalid.
    def input_array
      return [@input.to_sym] if @input && !@input.empty?
      return [@action.to_sym] if @action && !@action.empty?
      []
    end

    # Returns the WSSE header or an empty String in case WSSE was not set.
    def wsse_header
      return "" unless @wsse.respond_to? :header
      @wsse.header
    end

  end
end
