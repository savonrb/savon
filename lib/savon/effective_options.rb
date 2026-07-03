# frozen_string_literal: true

require "gyoku"
require "uri"

module Savon
  # Resolves the effective value of options whose answer combines more than
  # one source: the per-request options, the client options, the WSDL
  # document, and built-in defaults.
  #
  # {Savon::GlobalOptions} and {Savon::LocalOptions} store what the caller
  # said. EffectiveOptions answers what the request uses. It owns the
  # precedence rules and exposes one reader per resolvable option, so every
  # consumer of an option resolves it identically. Resolution is a pure read.
  # It never mutates the options or the WSDL document.
  class EffectiveOptions
    # @param operation_name [Symbol] the SOAP operation being called
    # @param wsdl [Wasabi::Document] the parsed WSDL, or an empty document
    #   when the client was configured without one
    # @param globals [Savon::GlobalOptions] the client-level options
    # @param locals [Savon::LocalOptions] the per-request options
    def initialize(operation_name, wsdl, globals, locals)
      @operation_name = operation_name
      @wsdl           = wsdl
      @globals        = globals
      @locals         = locals
    end

    # Resolves the SOAPAction of the request (SOAP 1.1 §6.1.1).
    #
    # An explicit local +:soap_action+ wins. A local +false+ or +nil+ disables
    # the action, so no SOAPAction HTTP header is sent and an enabled
    # +wsa:Action+ header stays empty. Without a local value the WSDL provides
    # the soapAction of the operation. Without a WSDL document the operation
    # name is converted to an XML tag as a best-effort default.
    #
    # @return [String, nil] the action, or +nil+ when explicitly disabled
    def soap_action
      return if @locals.include?(:soap_action) && !@locals[:soap_action]

      @locals[:soap_action] ||
        (@wsdl.document? && @wsdl.soap_action(@operation_name.to_sym)) ||
        Gyoku.xml_tag(@operation_name, key_converter: @globals[:convert_request_keys_to])
    end

    # Resolves the endpoint URL the request is sent to.
    #
    # A global +:endpoint+ wins over the service address of the WSDL. The
    # global +:host+ option replaces host and port of the WSDL address and
    # keeps scheme, path and query. The override is applied to a copy. The
    # WSDL document keeps its parsed address.
    #
    # @return [URI, String, nil] the endpoint as provided by the winning source
    def endpoint
      return @globals[:endpoint] if @globals[:endpoint]
      return @wsdl.endpoint unless @globals[:host]

      host_url = URI.parse(@globals[:host])
      url      = @wsdl.endpoint.dup
      url.host = host_url.host
      url.port = host_url.port
      url
    end

    # Resolves the WSSE auth credentials passed to Akami. A local value takes
    # precedence over the global one. A local +false+ disables auth even when a
    # global value is set. A local +nil+ leaves the option unset and falls
    # through to the global value.
    #
    # @return [Array<String>, false, nil] the credentials, +false+ to disable,
    #   or +nil+ when unset in both scopes
    def wsse_auth
      prefer_local(:wsse_auth)
    end

    # Resolves whether Akami emits a +wsu:Timestamp+ header, using the same
    # local-over-global rule as {#wsse_auth}. A local +false+ disables it and a
    # local +nil+ keeps the global value.
    #
    # @return [Boolean, nil]
    def wsse_timestamp
      prefer_local(:wsse_timestamp)
    end

    # Resolves the WSSE signature used to sign the request. This option is a
    # signature object or +nil+ and has no "disable" value, so any falsy local
    # value falls back to the global one. {Savon::Builder} and {Savon::Header}
    # both read it and must resolve it identically.
    #
    # @return [Akami::WSSE::Signature, nil]
    def wsse_signature
      @locals[:wsse_signature] || @globals[:wsse_signature]
    end

    # Resolves the SOAP header content. When both scopes provide a Hash the two
    # are merged and local keys win. Otherwise the local value is preferred and
    # falls back to the global one. A Hash is rendered to XML by Gyoku. A String,
    # or any object responding to +#to_s+, is used verbatim.
    #
    # @return [Hash, String, nil]
    def soap_header
      global = @globals[:soap_header]
      local  = @locals[:soap_header]

      if global.is_a?(Hash) && local.is_a?(Hash)
        global.merge(local)
      else
        local || global
      end
    end

    private

    # Resolves an option where a local +false+ is meaningful and disables it.
    # Only a local +nil+ falls through to the global value. Contrast with
    # {#wsse_signature}, which treats any falsy local as unset.
    #
    # @param key [Symbol] the option name
    # @return [Object, nil] the local value unless it is +nil+, else the global
    def prefer_local(key)
      @locals[key].nil? ? @globals[key] : @locals[key]
    end
  end
end
