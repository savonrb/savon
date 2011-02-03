require "savon/core_ext/object"
require "savon/core_ext/string"

module Savon
  module WSDL

    # = Savon::WSDL::Parser
    #
    # Serves as a stream listener for parsing WSDL documents.
    class Parser

      # The main sections of a WSDL document.
      Sections = %w(definitions types message portType binding service)

      def initialize
        @path = []
        @operations = {}
        @namespaces = {}
        @messages = {}
        @input_message = {}
        @types = {}
        @element_form_default = :unqualified
      end

      # Returns the namespace URI.
      attr_reader :namespace

      # Returns the SOAP operations.
      attr_reader :operations

      # Returns a map from the message name to its element
      attr_reader :messages

      # Returns a map from the action to its input message name
      attr_reader :input_message

      # Returns a map from a type name to a hash with type information
      attr_reader :types

      # Returns the SOAP endpoint.
      attr_reader :endpoint

      # Returns the elementFormDefault value.
      attr_reader :element_form_default

      # Hook method called when the stream parser encounters a starting tag.
      def tag_start(tag, attrs)
        # read xml namespaces if root element
        read_namespaces(attrs) if @path.empty?

        tag, namespace = tag.split(":").reverse
        @path << [tag, attrs]

        if @section == :types && tag == "schema"
          @element_form_default = attrs["elementFormDefault"].to_sym if attrs["elementFormDefault"]
          @type_context = []
        end

        if @section == :types && !@type_context.nil? && type_defining_tag(tag, attrs)
          if @type_context == []
            @types[attrs["name"]] = {:todo => "to be determined"}
          end

          @type_context.push(attrs["name"])
        end

        if @section == :binding && tag == "binding"
          # ensure that we are in an wsdl/soap namespace
          @section = nil unless @namespaces[namespace].starts_with? "http://schemas.xmlsoap.org/wsdl/soap"
        end

        if @section == :definitions && tag == "message"
          @current_message = attrs["name"]
        end

        if @section == :message && tag == "part" && attrs["name"] == "parameters"
          @messages[@current_message] = attrs["element"].strip_namespace
        end

        if @section == :portType && tag == "operation"
          @current_action = attrs["name"]
        end

        if @section == :portType && tag == "input"
          @input_message[@current_action] = attrs["message"].strip_namespace
        end

        @section = tag.to_sym if Sections.include?(tag) && depth <= 2

        @namespace ||= attrs["targetNamespace"] if @section == :definitions
        @endpoint ||= URI(URI.escape(attrs["location"])) if @section == :service && tag == "address"

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
        start_tag, attrs = @path.pop

        if @section == :binding && @input && tag.strip_namespace == "operation"
          # no soapAction attribute found till now
          operation_from tag, "soapAction" => @input
        end

        @section = :definitions if Sections.include?(tag) && depth <= 1

        tag_only, namespace = tag.split(":").reverse
        if @section == :types && type_defining_tag(tag_only, attrs)
          @type_context.pop
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

      def type_defining_tag(tag, attrs)
        tag == "element" || (tag == "complexType" && attrs["name"])
      end

      # Catches calls to unimplemented hook methods.
      def method_missing(method, *args)
      end

    end
  end
end
