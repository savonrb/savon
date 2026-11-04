# frozen_string_literal: true

require "gyoku"
require "securerandom"

module Savon
  # Emits the WS-Addressing message addressing properties of a request
  # (WS-Addressing 1.0 - Core §3.2): +wsa:Action+, +wsa:To+ and +wsa:MessageID+.
  #
  # This object owns everything Savon knows about WS-Addressing: the namespace,
  # whether the headers are emitted at all, and how the resolved SOAPAction and
  # endpoint map onto the addressing properties. It works on plain values.
  # {Savon::Header} resolves them via {Savon::EffectiveOptions} and constructs
  # this object, keeping option resolution and WSA emission separate.
  class Addressing
    # The WS-Addressing 1.0 namespace,
    # https://www.w3.org/TR/ws-addr-core/#namespaces.
    NAMESPACE = "http://www.w3.org/2005/08/addressing"

    # @param enabled [Object] whether the headers are emitted, any truthy value
    #   counts (the +:use_wsa_headers+ global)
    # @param action [String, nil] the resolved SOAPAction, emitted as
    #   +wsa:Action+, or +nil+ when the caller disabled it
    # @param to [URI, String, nil] the resolved endpoint, emitted as +wsa:To+
    def initialize(enabled:, action: nil, to: nil)
      @enabled = enabled
      @action  = action
      @to      = to
    end

    # @return [Boolean] whether the WS-Addressing headers are emitted
    def enabled?
      !!@enabled
    end

    # Returns the namespace declaration the enclosing Header element needs.
    # The +wsa+ prefix is declared once on the Header, not on each child.
    #
    # @return [Hash{String => String}] +{"xmlns:wsa" => NAMESPACE}+, or an
    #   empty Hash when disabled
    def namespace_attributes
      enabled? ? { "xmlns:wsa" => NAMESPACE } : {}
    end

    # Renders the three addressing properties, each rendering with a freshly
    # generated +wsa:MessageID+. A +nil+ action or destination is emitted as
    # an +xsi:nil+ element rather than being dropped.
    #
    # @return [String] the header elements, or an empty String when disabled
    def to_xml
      return "" unless enabled?

      Gyoku.xml(
        "wsa:Action"    => @action,
        "wsa:To"        => @to,
        "wsa:MessageID" => "urn:uuid:#{SecureRandom.uuid}"
      )
    end
  end
end
