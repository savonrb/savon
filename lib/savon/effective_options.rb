# frozen_string_literal: true

module Savon
  # Resolves the effective value of options that can be set in both the global
  # (client) and the local (per-request) scope.
  #
  # The WSSE options and +:soap_header+ accept a client-level value on
  # {Savon::GlobalOptions} and a per-request value on {Savon::LocalOptions}.
  # EffectiveOptions owns those precedence rules and exposes one reader per
  # resolvable option, so every consumer of a dual-scope option resolves it
  # identically. It never mutates the underlying options.
  class EffectiveOptions
    # @param globals [Savon::GlobalOptions] the client-level options
    # @param locals [Savon::LocalOptions] the per-request options
    def initialize(globals, locals)
      @globals = globals
      @locals  = locals
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
