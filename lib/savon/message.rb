require "savon/qualified_message"
require "gyoku"

module Savon
  class Message

    def initialize(message_namespace, operation_name, namespace_identifier, types, used_namespaces, message, element_form_default, key_converter)
      @message_namespace = message_namespace
      @operation_name = operation_name
      @namespace_identifier = namespace_identifier
      @types = types
      @used_namespaces = used_namespaces

      @message = message
      @element_form_default = element_form_default
      @key_converter = key_converter
    end

    def to_s
      return @message.to_s unless @message.kind_of? Hash

      if @element_form_default == :qualified
        translated_operation_name = Gyoku.xml_tag(@operation_name, :key_converter => @key_converter).to_s
        @message = QualifiedMessage.new(@message_namespace, @types, @used_namespaces, @request_key_converter).to_hash(@message, [translated_operation_name])
      end

      gyoku_options = {
        :element_form_default => @element_form_default,
        :namespace            => @message_namespace,
        :key_converter        => @key_converter
      }

      Gyoku.xml(@message, gyoku_options)
    end

  end
end
