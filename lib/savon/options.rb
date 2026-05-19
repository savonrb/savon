# frozen_string_literal: true

require "logger"
require "httpi"

module Savon
  # Base class for GlobalOptions and LocalOptions.
  # Stores options in a hash, dispatches setter calls by method name,
  # raises UnknownOptionError for anything not defined on the subclass.
  class Options
    def initialize(options = {})
      @options = {}
      assign options
    end

    attr_reader :option_type

    def [](option)
      @options[option]
    end

    def []=(option, value)
      value = [value].flatten
      send(option, *value)
    end

    def include?(option)
      @options.key? option
    end

    private

    def assign(options)
      options.each do |option, value|
        send(option, value)
      end
    end

    def method_missing(option, _)
      raise UnknownOptionError, "Unknown #{option_type} option: #{option.inspect}"
    end
  end

  # Options available in both GlobalOptions and LocalOptions.
  # Currently covers WSSE authentication and timestamp headers.
  module SharedOptions
    # WSSE auth credentials for Akami.
    # Local will override the global wsse_auth value, e.g.
    #   global == [user, pass] && local == [user2, pass2] => [user2, pass2]
    #   global == [user, pass] && local == false => false
    #   global == [user, pass] && local == nil   => [user, pass]
    def wsse_auth(*credentials)
      credentials.flatten!
      @options[:wsse_auth] =
        if credentials.size == 1
          credentials.first
        else
          credentials
        end
    end

    # Instruct Akami to enable wsu:Timestamp headers.
    # Local will override the global wsse_timestamp value, e.g.
    #   global == true && local == true  => true
    #   global == true && local == false => false
    #   global == true && local == nil   => true
    def wsse_timestamp(timestamp = true)
      @options[:wsse_timestamp] = timestamp
    end

    def wsse_signature(signature)
      @options[:wsse_signature] = signature
    end
  end

  # HTTPI-specific transport options included in GlobalOptions.
  #
  # Every option in this module is handled by HTTPI and has no effect when
  # transport: :faraday is set. Faraday callers configure these concerns
  # directly on the Faraday::Connection returned by client.faraday.
  module HTTPITransportOptions
    # Maps each httpi-only option to the Faraday equivalent so the
    # error raised at init tells the caller exactly what to do instead.
    # Options with a :default entry are only flagged when the caller
    # sets a value that differs from the GlobalOptions default.
    FARADAY_INCOMPATIBLE_GLOBALS = {
      proxy: { hint: "client.faraday.proxy = url" },
      open_timeout: { hint: "client.faraday.options.timeout = N" },
      read_timeout: { hint: "client.faraday.options.timeout = N" },
      write_timeout: { hint: "client.faraday.options.write_timeout = N" },
      ssl_version: { hint: "client.faraday.ssl.version = version" },
      ssl_min_version: { hint: "client.faraday.ssl.min_version = version" },
      ssl_max_version: { hint: "client.faraday.ssl.max_version = version" },
      ssl_verify_mode: { hint: "client.faraday.ssl.verify = true/false" },
      ssl_cert_key_file: { hint: "client.faraday.ssl.client_key_file = path" },
      ssl_cert_key: { hint: "client.faraday.ssl.client_key = key" },
      ssl_cert_key_password: { hint: "configure ssl context on client.faraday.ssl" },
      ssl_cert_file: { hint: "client.faraday.ssl.client_cert_file = path" },
      ssl_cert: { hint: "client.faraday.ssl.client_cert = cert" },
      ssl_ca_cert_file: { hint: "client.faraday.ssl.ca_file = path" },
      ssl_ca_cert: { hint: "client.faraday.ssl.ca_cert = cert" },
      ssl_ciphers: { hint: "client.faraday.ssl.ciphers = ciphers" },
      ssl_ca_cert_path: { hint: "client.faraday.ssl.ca_path = path" },
      ssl_cert_store: { hint: "client.faraday.ssl.cert_store = store" },
      basic_auth: { hint: "client.faraday.request :basic_auth, user, pass" },
      digest_auth: { hint: "client.faraday.request :authorization, :Digest, credentials" },
      ntlm: { hint: "client.faraday.request :ntlm, user, pass" },
      follow_redirects: { hint: "client.faraday.use :follow_redirects", default: false },
      adapter: { hint: "client.faraday.adapter :net_http", default: nil }
    }.freeze

    # Validates that the chosen transport is compatible with the options set.
    # Must be called after all options (including any block-form options) are set.
    # Collects every conflict and raises a single InitializationError listing all
    # problems and solutions at once.
    def validate_transport!
      return unless self[:transport] == :faraday

      unless faraday_loaded?
        raise InitializationError,
              "transport: :faraday requires the faraday gem.\n" \
              "Add to your Gemfile: gem 'faraday'"
      end

      violations = FARADAY_INCOMPATIBLE_GLOBALS.filter_map do |option, config|
        next unless include?(option)
        next if config.key?(:default) && self[option] == config[:default]

        "  #{option} - Use: #{config[:hint]}"
      end

      return if violations.empty?

      raise InitializationError,
            "The following options are not supported with transport: :faraday:\n" +
            violations.join("\n")
    end

    # Proxy server to use for all requests.
    def proxy(proxy)
      @options[:proxy] = proxy unless proxy.nil?
    end

    # Open timeout in seconds.
    def open_timeout(open_timeout)
      @options[:open_timeout] = open_timeout
    end

    # Read timeout in seconds.
    def read_timeout(read_timeout)
      @options[:read_timeout] = read_timeout
    end

    # Write timeout in seconds.
    def write_timeout(write_timeout)
      @options[:write_timeout] = write_timeout
    end

    # Specifies the SSL version to use.
    def ssl_version(version)
      @options[:ssl_version] = version
    end

    # Specifies the minimum SSL version to use.
    def ssl_min_version(version)
      @options[:ssl_min_version] = version
    end

    # Specifies the maximum SSL version to use.
    def ssl_max_version(version)
      @options[:ssl_max_version] = version
    end

    # Whether and how to verify the SSL connection.
    def ssl_verify_mode(verify_mode)
      @options[:ssl_verify_mode] = verify_mode
    end

    # Sets the cert key file to use.
    def ssl_cert_key_file(file)
      @options[:ssl_cert_key_file] = file
    end

    # Sets the cert key to use.
    def ssl_cert_key(key)
      @options[:ssl_cert_key] = key
    end

    # Sets the cert key password to use.
    def ssl_cert_key_password(password)
      @options[:ssl_cert_key_password] = password
    end

    # Sets the cert file to use.
    def ssl_cert_file(file)
      @options[:ssl_cert_file] = file
    end

    # Sets the cert to use.
    def ssl_cert(cert)
      @options[:ssl_cert] = cert
    end

    # Sets the CA cert file to use.
    def ssl_ca_cert_file(file)
      @options[:ssl_ca_cert_file] = file
    end

    # Sets the CA cert to use.
    def ssl_ca_cert(cert)
      @options[:ssl_ca_cert] = cert
    end

    # Sets the SSL ciphers to use.
    def ssl_ciphers(ciphers)
      @options[:ssl_ciphers] = ciphers
    end

    # Sets the CA cert path.
    def ssl_ca_cert_path(path)
      @options[:ssl_ca_cert_path] = path
    end

    # Sets the SSL cert store.
    def ssl_cert_store(store)
      @options[:ssl_cert_store] = store
    end

    # HTTP basic auth credentials.
    def basic_auth(*credentials)
      @options[:basic_auth] = credentials.flatten
    end

    # HTTP digest auth credentials.
    def digest_auth(*credentials)
      @options[:digest_auth] = credentials.flatten
    end

    # NTLM auth credentials.
    def ntlm(*credentials)
      @options[:ntlm] = credentials.flatten
    end

    # Instruct requests to follow HTTP redirects.
    def follow_redirects(follow_redirects)
      @options[:follow_redirects] = follow_redirects
    end

    # Instruct Savon which HTTPI adapter to use instead of the default.
    def adapter(adapter)
      @options[:adapter] = adapter
    end

    private

    # Attempts to load faraday. Returns true if available, false on LoadError.
    def faraday_loaded?
      require "faraday"
      true
    rescue LoadError
      false
    end
  end

  # Client-level options applied to every request made by a Savon::Client instance.
  # Covers service location, SOAP configuration, logging, response parsing,
  # and transport selection. HTTPI-specific options (proxy, timeouts, SSL, auth)
  # come from HTTPITransportOptions.
  class GlobalOptions < Options
    include SharedOptions
    include HTTPITransportOptions

    def initialize(options = {})
      @option_type = :global

      defaults = {
        :encoding                    => "UTF-8",
        :soap_version                => 1,
        :namespaces                  => {},
        :logger                      => Logger.new($stdout),
        :log                         => false,
        :log_headers                 => true,
        :filters                     => [],
        :pretty_print_xml            => false,
        :raise_errors                => true,
        :strip_namespaces            => true,
        :delete_namespace_attributes => false,
        :convert_response_tags_to    => lambda { |tag| StringUtils.snakecase(tag).to_sym},
        :convert_attributes_to       => lambda { |k,v| [k,v] },
        :multipart                   => false,
        :use_wsa_headers             => false,
        :no_message_tag              => false,
        :unwrap                      => false,
        :host                        => nil,
        :transport                   => :httpi,

        # httpi transport defaults
        :adapter                     => nil,
        :follow_redirects            => false
      }

      options = defaults.merge(options)

      # this option is a shortcut on the logger which needs to be set
      # before it can be modified to set the option.
      delayed_level = options.delete(:log_level)

      super(options)

      log_level(delayed_level) unless delayed_level.nil?
    end

    # Location of the local or remote WSDL document.
    def wsdl(wsdl_address)
      @options[:wsdl] = wsdl_address
    end

    # Set a different host for actions in the WSDL.
    def host(host)
      @options[:host] = host
    end

    # SOAP endpoint.
    def endpoint(endpoint)
      @options[:endpoint] = endpoint
    end

    # Target namespace.
    def namespace(namespace)
      @options[:namespace] = namespace
    end

    # The namespace identifier.
    def namespace_identifier(identifier)
      @options[:namespace_identifier] = identifier
    end

    # Namespaces for the SOAP envelope.
    def namespaces(namespaces)
      @options[:namespaces] = namespaces
    end

    # A Hash of HTTP headers sent with every request.
    def headers(headers)
      @options[:headers] = headers
    end

    # The encoding to use. Defaults to "UTF-8".
    def encoding(encoding)
      @options[:encoding] = encoding
    end

    # The global SOAP header. Expected to be a Hash or responding to #to_s.
    def soap_header(header)
      @options[:soap_header] = header
    end

    # Sets whether elements should be :qualified or :unqualified.
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

    # Whether or not to log.
    def log(log)
      HTTPI.log = log
      @options[:log] = log
    end

    # The logger to use. Defaults to a Savon::Logger instance.
    def logger(logger)
      HTTPI.logger = logger
      @options[:logger] = logger
    end

    # Changes the Logger's log level.
    def log_level(level)
      levels = { :debug => 0, :info => 1, :warn => 2, :error => 3, :fatal => 4 }

      unless levels.include? level
        raise ArgumentError, "Invalid log level: #{level.inspect}\n" \
                             "Expected one of: #{levels.keys.inspect}"
      end

      @options[:logger].level = levels[level]
    end

    # Whether to log headers.
    def log_headers(log_headers)
      @options[:log_headers] = log_headers
    end

    # A list of XML tags to filter from logged SOAP messages.
    def filters(*filters)
      @options[:filters] = filters.flatten
    end

    # Whether to pretty print request and response XML log messages.
    def pretty_print_xml(pretty_print_xml)
      @options[:pretty_print_xml] = pretty_print_xml
    end

    # Instruct Nori whether to strip namespaces from XML nodes.
    def strip_namespaces(strip_namespaces)
      @options[:strip_namespaces] = strip_namespaces
    end

    # Instruct Nori whether to delete namespace attributes from XML nodes.
    def delete_namespace_attributes(delete_namespace_attributes)
      @options[:delete_namespace_attributes] = delete_namespace_attributes
    end

    # Tell Gyoku how to convert Hash key Symbols to XML tags.
    # Accepts one of :lower_camelcase, :camelcase, :upcase, or :none.
    def convert_request_keys_to(converter)
      @options[:convert_request_keys_to] = converter
    end

    # Tell Gyoku to unwrap Array of Hashes.
    # Accepts a boolean, defaults to false.
    def unwrap(unwrap)
      @options[:unwrap] = unwrap
    end

    # Tell Nori how to convert XML tags from the SOAP response into Hash keys.
    # Accepts a lambda or a block which receives an XML tag and returns a Hash key.
    # Defaults to converting tags to snakecase Symbols.
    def convert_response_tags_to(converter = nil, &block)
      @options[:convert_response_tags_to] = block || converter
    end

    # Tell Nori how to convert XML attributes on tags from the SOAP response into Hash keys.
    # Accepts a lambda or a block which receives an XML tag and returns a Hash key.
    # Defaults to doing nothing.
    def convert_attributes_to(converter = nil, &block)
      @options[:convert_attributes_to] = block || converter
    end

    # Instruct Savon to create a multipart response if available.
    def multipart(multipart)
      @options[:multipart] = multipart
    end

    # Enable inclusion of WS-Addressing headers.
    def use_wsa_headers(use)
      @options[:use_wsa_headers] = use
    end

    # Suppress the message tag wrapper around the SOAP body.
    def no_message_tag(bool)
      @options[:no_message_tag] = bool
    end

    # HTTP transport to use. Accepts :httpi (default) or :faraday.
    # When set to :faraday, configure transport concerns directly on the
    # Faraday::Connection returned by client.faraday instead of using
    # the HTTPITransportOptions.
    def transport(transport)
      @options[:transport] = transport
    end
  end

  # Per-request options passed to client.call.
  # Overrides or extends the matching GlobalOptions for a single SOAP operation.
  class LocalOptions < Options
    include SharedOptions

    def initialize(options = {})
      @option_type = :local

      defaults = {
        :advanced_typecasting => true,
        :response_parser      => :nokogiri,
        :multipart            => false
      }

      super defaults.merge(options)
    end

    # The local SOAP header. Expected to be a Hash or respond to #to_s.
    # Will be merged with the global SOAP header if both are Hashes.
    # Otherwise the local option will be preferred.
    def soap_header(header)
      @options[:soap_header] = header
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

    # Attributes for the SOAP message tag.
    def attributes(attributes)
      @options[:attributes] = attributes
    end

    # Attachments for the SOAP message (https://www.w3.org/TR/SOAP-attachments)
    #
    # should pass an Array or a Hash; items should be path strings or
    #  { filename: 'file.name', content: 'content' } objects
    # The Content-ID in multipart message sections will be the filename or the key if Hash is given
    #
    # usage examples:
    #
    #    response = client.call :operation1 do
    #      message param1: 'value'
    #      attachments [
    #        { filename: 'x1.xml', content: '<xml>abc</xml>'},
    #        { filename: 'x2.xml', content: '<xml>abc</xml>'}
    #      ]
    #    end
    #    # Content-ID will be x1.xml and x2.xml
    #
    #    response = client.call :operation1 do
    #      message param1: 'value'
    #      attachments 'x1.xml' => '/tmp/1281ab7d7d.xml', 'x2.xml' => '/tmp/4c5v8e833a.xml'
    #    end
    #    # Content-ID will be x1.xml and x2.xml
    #
    #    response = client.call :operation1 do
    #      message param1: 'value'
    #      attachments [ '/tmp/1281ab7d7d.xml', '/tmp/4c5v8e833a.xml']
    #    end
    #    # Content-ID will be 1281ab7d7d.xml and 4c5v8e833a.xml
    #
    # The Content-ID is important if you want to refer to the attachments from the SOAP request
    def attachments(attachments)
      @options[:attachments] = attachments
    end

    # Value of the SOAPAction HTTP header.
    def soap_action(soap_action)
      @options[:soap_action] = soap_action
    end

    # Cookies to be used for the next request.
    def cookies(cookies)
      @options[:cookies] = cookies
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

    # Instruct Savon to create a multipart response if available.
    def multipart(multipart)
      @options[:multipart] = multipart
    end

    # Per-request HTTP headers. Merged with global headers for each request.
    def headers(headers)
      @options[:headers] = headers
    end
  end
end
