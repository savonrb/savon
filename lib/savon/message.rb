require "savon/qualified_message"
require "gyoku"

module Savon
  class Message

    def initialize(operation_name, namespace_identifier, used_namespaces, message, element_form_default)
      @operation_name = operation_name
      @namespace_identifier = namespace_identifier
      @used_namespaces = used_namespaces

      @message = message
      @element_form_default = element_form_default
    end

    def to_s
      return @message.to_s unless @message.kind_of? Hash

      @string = begin
        if @element_form_default == :qualified
          @message = QualifiedMessage.new(@used_namespaces).to_hash(@message, [@operation_name])
        end

        Gyoku.xml @message, :element_form_default => @element_form_default, :namespace => @namespace_identifier
      end
    end

  end
end
