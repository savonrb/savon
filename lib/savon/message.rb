# frozen_string_literal: true

require "savon/qualified_message"
require "gyoku"

module Savon
  class Message
    def initialize(message_tag, namespace_identifier, types, used_namespaces, message, element_form_default, key_converter, unwrap)
      @message_tag = message_tag
      @namespace_identifier = namespace_identifier
      @types = types
      @used_namespaces = used_namespaces

      @message = message
      @element_form_default = element_form_default
      @key_converter = key_converter
      @unwrap = unwrap
    end

    def to_s
      return @message.to_s unless @message.is_a? Hash

      if @element_form_default == :qualified
        @message = QualifiedMessage.new(@types, @used_namespaces, @key_converter).to_hash(@message, [@message_tag.to_s])
      elsif schema_order?(@message)
        unqualified = QualifiedMessage.new(@types, @used_namespaces, @key_converter, qualify: false)
        @message = unqualified.to_hash(@message, [@message_tag.to_s])
      end

      gyoku_options = {
        element_form_default: @element_form_default,
        namespace: @namespace_identifier,
        key_converter: @key_converter,
        unwrap: @unwrap
      }

      Gyoku.xml(@message, gyoku_options)
    end

    private

    def schema_order?(value)
      case value
      when Hash then QualifiedMessage.order_option(value) == :use_schema || value.each_value.any? { |nested| schema_order?(nested) }
      when Array then value.any? { |nested| schema_order?(nested) }
      else false
      end
    end
  end
end
