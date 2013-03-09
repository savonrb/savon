require "savon/qualified_message"
require "gyoku"

module Savon
  class Message

    def initialize(operation_name, namespace_identifier, types, used_namespaces, message, element_form_default, key_converter)
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
        # XXX: there is no `@request_key_converter` instance variable!
        #      the third argument is therefore always `nil`. [dh, 2013-03-09]
        @message = QualifiedMessage.new(@types, @used_namespaces, @request_key_converter).to_hash(@message, [translated_operation_name])
      end

      gyoku_options = {
        :element_form_default => @element_form_default,
        :namespace            => @namespace_identifier,
        :key_converter        => @key_converter
      }

      Gyoku.xml(@message, gyoku_options)
    end

  end
end
