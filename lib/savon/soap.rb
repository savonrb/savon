module Savon

  # = Savon::SOAP
  #
  # Savon::SOAP represents the SOAP request. Pass a block to your SOAP call and the SOAP object is
  # passed to it as the first argument. The object allows setting the SOAP version, header, body
  # and namespaces per request.
  #
  # == Body
  #
  # The body method lets you specify parameters to be received by the SOAP action.
  #
  # You can either pass in a hash (which will be translated to XML via Hash.to_soap_xml):
  #
  #   response = client.get_user_by_id do |soap|
  #     soap.body = { :id => 123 }
  #   end
  #
  # Or a string containing the raw XML:
  #
  #   response = client.get_user_by_id do |soap|
  #     soap.body = "<id>123</id>"
  #   end
  #
  # Request output:
  #
  #   <env:Envelope
  #       xmlns:wsdl="http://example.com/user/1.0/UserService"
  #       xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  #     <env:Body>
  #       <wsdl:getUserById><id>123</id></wsdl:getUserById>
  #     </env:Body>
  #   </env:Envelope>
  #
  # Please look at the documentation of Hash.to_soap_xml for some more information.
  #
  # == Version
  #
  # Savon defaults to SOAP 1.1. In case your service uses SOAP 1.2, you can use the version method
  # to change the default per request.
  #
  #   response = client.get_all_users do |soap|
  #     soap.version = 2
  #   end
  #
  # You can also change the default to SOAP 1.2 for all request:
  #
  #   Savon::SOAP.version = 2
  #
  # == Header
  #
  # If you need to add custom XML into the SOAP header, you can use the header method.
  #
  # The value is expected to be a hash (which will be translated to XML via Hash.to_soap_xml):
  #
  #   response = client.get_all_users do |soap|
  #     soap.header["specialApiKey"] = "secret"
  #   end
  #
  # Or a string containing the raw XML:
  #
  #   response = client.get_all_users do |soap|
  #     soap.header = "<specialApiKey>secret</specialApiKey>"
  #   end
  #
  # Request output:
  #
  #   <env:Envelope
  #       xmlns:wsdl="http://example.com/user/1.0/UserService"
  #       xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  #     <env:Header>
  #       <specialApiKey>secret</specialApiKey>
  #     </env:Header>
  #     <env:Body>
  #       <wsdl:getAllUsers></wsdl:getAllUsers>
  #     </env:Body>
  #   </env:Envelope>
  #
  # == Namespaces
  #
  # The namespaces method contains a hash of attributes for the SOAP envelope. You can overwrite it
  # or add additional attributes.
  #
  #   response = client.get_all_users do |soap|
  #     soap.namespaces["xmlns:domains"] = "http://domains.example.com"
  #   end
  #
  # Request output:
  #
  #   <env:Envelope
  #       xmlns:wsdl="http://example.com/user/1.0/UserService"
  #       xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
  #       xmlns:domains="http://domains.example.com">
  #     <env:Body>
  #       <wsdl:getAllUsers></wsdl:getAllUsers>
  #     </env:Body>
  #   </env:Envelope>
  #
  # == Input
  #
  # You can change the name of the SOAP input tag in case you need to.
  #
  #   response = client.get_all_users do |soap|
  #     soap.input = "GetAllUsersRequest"
  #   end
  #
  # Request output:
  #
  #   <env:Envelope
  #       xmlns:wsdl="http://example.com/user/1.0/UserService"
  #       xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  #     <env:Body>
  #       <wsdl:GetAllUsersRequest></wsdl:GetAllUsersRequest>
  #     </env:Body>
  #   </env:Envelope>
  class SOAP

    # Supported SOAP versions.
    Versions = [1, 2]

    # SOAP namespaces by SOAP version.
    Namespace = {
      1 => "http://schemas.xmlsoap.org/soap/envelope/",
      2 => "http://www.w3.org/2003/05/soap-envelope"
    }

    # Content-Types by SOAP version.
    ContentType = { 1 => "text/xml", 2 => "application/soap+xml" }

    # SOAP xs:dateTime format.
    DateTimeFormat = "%Y-%m-%dT%H:%M:%SZ"

    # SOAP xs:dateTime Regexp.
    DateTimeRegexp = /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/

    # The global SOAP version.
    @@version = 1

    # Returns the global SOAP version.
    def self.version
      @@version
    end

    # Sets the global SOAP version.
    def self.version=(version)
      @@version = version if Versions.include? version
    end

    # Sets the global SOAP header. Expected to be a Hash that can be translated to XML via
    # Hash.to_soap_xml or any other Object responding to to_s.
    def self.header=(header)
      @@header = header
    end

    # Returns the global SOAP header. Defaults to an empty Hash.
    def self.header
      @@header ||= {}
    end

    # Sets the global namespaces. Expected to be a Hash containing the namespaces (keys) and the
    # corresponding URI's (values).
    def self.namespaces=(namespaces)
      @@namespaces = namespaces if namespaces.kind_of? Hash
    end

    # Returns the global namespaces. A Hash containing the namespaces (keys) and the corresponding
    # URI's (values).
    def self.namespaces
      @@namespaces ||= {}
    end

    # Initialzes the SOAP object. Expects a SOAP +operation+ Hash along with an +endpoint+.
    def initialize(action, input, endpoint)
      @action, @input = action, input
      @endpoint = endpoint.kind_of?(URI) ? endpoint : URI(endpoint)
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

    # Sets the SOAP header. Expected to be a Hash that can be translated to XML via Hash.to_soap_xml
    # or any other Object responding to to_s.
    attr_writer :header

    # Returns the SOAP header. Defaults to an empty Hash.
    def header
      @header ||= {}
    end

    # Accessor for the SOAP body. Expected to be a Hash that can be translated to XML via Hash.to_soap_xml
    # or any other Object responding to to_s.
    attr_accessor :body

    # Accessor for overwriting the default SOAP request. Let's you specify completely custom XML.
    attr_accessor :xml

    # Sets the namespaces. Expected to be a Hash containing the namespaces (keys) and the
    # corresponding URI's (values).
    attr_writer :namespaces

    # Returns the namespaces. A Hash containing the namespaces (keys) and the corresponding URI's
    # (values). Defaults to a Hash containing an +xmlns:env+ key and the namespace for the current
    # SOAP version.
    def namespaces
      @namespaces ||= { "xmlns:env" => Namespace[version] }
    end

    # Convenience method for setting the +xmlns:wsdl+ namespace.
    def namespace=(namespace)
      namespaces["xmlns:wsdl"] = namespace
    end

    # Sets the SOAP version.
    def version=(version)
      @version = version if Versions.include? version
    end

    # Returns the SOAP version. Defaults to the global default.
    def version
      @version ||= self.class.version
    end

    # Returns the SOAP envelope XML.
    def to_xml
      unless @xml
        @builder.instruct!
        @xml = @builder.env :Envelope, merged_namespaces do |xml|
          xml.env(:Header) { xml << merged_header } unless merged_header.empty?
          xml_body xml
        end
      end
      @xml
    end

  private

    # Returns a String containing the global and per request header.
    def merged_header
      if self.class.header.kind_of?(Hash) && header.kind_of?(Hash)
        merged_header = self.class.header.merge(header).to_soap_xml
      else
        global_header = self.class.header.to_soap_xml rescue self.class.header.to_s
        request_header = header.to_soap_xml rescue header.to_s
        merged_header = global_header + request_header
      end
      merged_header + wsse_header
    end

    # Returns the WSSE header or an empty String in case WSSE was not set.
    def wsse_header
      @wsse.respond_to?(:header) ? @wsse.header : ""
    end

    # Adds a SOAP XML body to a given +xml+ Object.
    def xml_body(xml)
      xml.env(:Body) do
        xml.tag!(:wsdl, *input_array) { xml << (@body.to_soap_xml rescue @body.to_s) }
      end
    end

    # Returns a Hash containing the global and per request namespaces.
    def merged_namespaces
      self.class.namespaces.merge namespaces
    end

    # Returns an Array of SOAP input names to append to the wsdl namespace. Defaults to use the
    # name of the SOAP action. May return an empty Array in case the specified SOAP input seems
    # to be invalid.
    def input_array
      if input.kind_of?(Array) && !input.blank?
        [input[0].to_sym, input[1]]
      elsif !input.blank?
        [input.to_sym]
      elsif !action.blank?
        [action.to_sym]
      else
        []
      end
    end

  end
end