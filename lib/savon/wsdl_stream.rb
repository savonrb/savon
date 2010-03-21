module Savon

  # = Savon::WSDLStream
  #
  # Savon::WSDLStream serves as a stream listener for parsing the WSDL document.
  class WSDLStream

    # The main sections of a WSDL document.
    Sections = %w(definitions types message portType binding service)

    def initialize
      @path, @operations, @namespaces = [], {}, {}
    end

    # Returns the namespace URI.
    attr_reader :namespace_uri

    # Returns the SOAP operations.
    attr_reader :operations

    # Returns the SOAP endpoint.
    attr_reader :soap_endpoint

    # Hook method called when the stream parser encounters a starting tag.
    def tag_start(tag, attrs)
      # read xml namespaces if root element
      read_namespaces(attrs) if @path.empty?

      tag, namespace = tag.split(":").reverse
      @path << tag

      if @section == :binding && tag == "binding"
        # ensure that we are in an wsdl/soap namespace
        @section = nil unless @namespaces[namespace].starts_with? "http://schemas.xmlsoap.org/wsdl/soap"
      end

      @section = tag.to_sym if Sections.include?(tag) && depth <= 2

      @namespace_uri ||= attrs["targetNamespace"] if @section == :definitions
      @soap_endpoint ||= URI(attrs["location"]) if @section == :service && tag == "address"

      operation_from tag, attrs if @section == :binding && tag == "operation"
    end

    # Returns our current depth in the WSDL document.
    def depth
      @path.size
    end

    # Reads namespace definitions from a given +attrs+ Hash.
    def read_namespaces(attrs)
      attrs.each do |key, value|
        @namespaces[key.strip_namespace] = value if key.starts_with? "xmlns:"
      end
    end

    # Hook method called when the stream parser encounters a closing tag.
    def tag_end(tag)
      @path.pop

      if @section == :binding && @input && tag.strip_namespace == "operation"
        # no soapAction attribute found till now
        operation_from tag, "soapAction" => @input
      end
    end

    # Stores available operations from a given tag +name+ and +attrs+.
    def operation_from(tag, attrs)
      @input = attrs["name"] if attrs["name"]

      if attrs["soapAction"]
        @action = !attrs["soapAction"].blank? ? attrs["soapAction"] : @input
        @input = @action.split("/").last if !@input || @input.empty?

        @operations[@input.snakecase.to_sym] = { :action => @action, :input => @input }
        @input, @action = nil, nil
      end
    end

    # Catches calls to unimplemented hook methods.
    def method_missing(method, *args)
    end

  end
end
