require "savon/logger"

module Savon
  class Options

    def initialize(options = {})
      @options = {}
      assign options
    end

    def [](option)
      @options[option]
    end

    def []=(option, value)
      value = [value].flatten
      self.send(option, *value)
    end

    def include?(option)
      @options.key? option
    end

    private

    def assign(options)
      options.each do |option, value|
        self.send(option, value)
      end
    end

  end

  class GlobalOptions < Options

    def initialize(options = {})
      defaults = {
        :encoding                  => "UTF-8",
        :soap_version              => 1,
        :logger                    => Logger.new,
        :pretty_print_xml          => false,
        :raise_errors              => true,
        :strip_namespaces          => true,
        :convert_response_tags_to  => lambda { |tag| tag.snakecase.to_sym }
      }

      super defaults.merge(options)
    end

    # Location of the local or remote WSDL document.
    def wsdl(wsdl_address)
      @options[:wsdl] = wsdl_address
    end

    # SOAP endpoint.
    def endpoint(endpoint)
      @options[:endpoint] = endpoint
    end

    # Target namespace.
    def namespace(namespace)
      @options[:namespace] = namespace
    end

    # The namespace identifer.
    def namespace_identifier(identifier)
      @options[:namespace_identifier] = identifier
    end

    # Proxy server to use for all requests.
    def proxy(proxy)
      @options[:proxy] = proxy
    end

    # A Hash of HTTP headers.
    def headers(headers)
      @options[:headers] = headers
    end

    # Open timeout in seconds.
    def open_timeout(open_timeout)
      @options[:open_timeout] = open_timeout
    end

    # Read timeout in seconds.
    def read_timeout(read_timeout)
      @options[:read_timeout] = read_timeout
    end

    # The encoding to use. Defaults to "UTF-8".
    def encoding(encoding)
      @options[:encoding] = encoding
    end

    # The global SOAP header. Expected to be a Hash.
    def soap_header(header)
      @options[:soap_header] = header
    end

    # Sets whether elements should be :qualified or unqualified.
    # If you need to use this option, please open an issue and make
    # sure to add your WSDL document for debugging.
    def element_form_default(element_form_default)
      @options[:element_form_default] = element_form_default
    end

    # Can be used to change the SOAP envelope namespace identifier.
    # If you need to use this option, please open an issue and make
    # sure to add your WSDL document for debugging.
    def env_namespace(env_namespace)
      @options[:env_namespace] = env_namespace
    end

    # Changes the SOAP version to 1 or 2.
    def soap_version(soap_version)
      @options[:soap_version] = soap_version
    end

    # Whether or not to raise SOAP fault and HTTP errors.
    def raise_errors(raise_errors)
      @options[:raise_errors] = raise_errors
    end

    # The logger to use. Defaults to a Savon::Logger instance.
    def logger(logger)
      @options[:logger] = logger
    end

    # Whether to pretty print request and response XML log messages.
    def pretty_print_xml(pretty_print_xml)
      @options[:pretty_print_xml] = pretty_print_xml
    end

    # Used by Savon to store the last response to pass
    # its cookies to the next request.
    def last_response(last_response)
      @options[:last_response] = last_response
    end

    # HTTP basic auth credentials.
    def basic_auth(*credentials)
      @options[:basic_auth] = credentials.flatten
    end

    # HTTP digest auth credentials.
    def digest_auth(*credentials)
      @options[:digest_auth] = credentials.flatten
    end

    # WSSE auth credentials for Akami.
    def wsse_auth(*credentials)
      @options[:wsse_auth] = credentials.flatten
    end

    # Instruct Akami to enable wsu:Timestamp headers.
    def wsse_timestamp(*timestamp)
      @options[:wsse_timestamp] = timestamp.flatten
    end

    # Instruct Nori whether to strip namespaces from XML nodes.
    def strip_namespaces(strip_namespaces)
      @options[:strip_namespaces] = strip_namespaces
    end

    # Tell Nori how to convert XML tags from the SOAP response into Hash keys.
    # Accepts a lambda or a block which receives an XML tag and returns a Hash key.
    # Defaults to convert tags to snakecase Symbols.
    def convert_response_tags_to(converter = nil, &block)
      @options[:convert_response_tags_to] = block || converter
    end
  end

  class LocalOptions < Options

    def initialize(options = {})
      defaults = {
        :advanced_typecasting => true,
        :response_parser      => :nokogiri
      }

      super defaults.merge(options)
    end

    # The SOAP message to send. Expected to be a Hash or a String.
    def message(message)
      @options[:message] = message
    end

    # SOAP message tag (formerly known as SOAP input tag). If it's not set, Savon retrieves the name from
    # the WSDL document (if available). Otherwise, Gyoku converts the operation name into an XML element.
    def message_tag(message_tag)
      @options[:message_tag] = message_tag
    end

    # Value of the SOAPAction HTTP header.
    def soap_action(soap_action)
      @options[:soap_action] = soap_action
    end

    # The SOAP request XML to send. Expected to be a String.
    def xml(xml)
      @options[:xml] = xml
    end

    # Instruct Nori to use advanced typecasting.
    def advanced_typecasting(advanced)
      @options[:advanced_typecasting] = advanced
    end

    # Instruct Nori to use :rexml or :nokogiri to parse the response.
    def response_parser(parser)
      @options[:response_parser] = parser
    end

  end
end
