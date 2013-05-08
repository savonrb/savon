require 'uri'
require "wasabi/schema_collection"
require 'wasabi/schema'
require "wasabi/operations"

module Wasabi
  class Parser

    def initialize(document)
      @document = document
    end

    attr_reader :document

    def service_name
      @document.root['name']
    end

    def target_namespace
      @document.root['targetNamespace']
    end

    def namespaces
      @namespaces ||= collect_namespaces(@document, *schema_nodes)
    end

    # TODO: remove in separate commit if unused
    #def namespaces_by_value
      #@namespaces_by_value ||= namespaces.invert
    #end

    def schemas
      @schemas ||= begin
        schemas = schema_nodes.map { |node| Schema.new(node, self) }
        SchemaCollection.new(schemas)
      end
    end

    def operations
      @operations ||= Operations.new(self).operations
    end

    # TODO: this works for now, but it should be moved into the Operation,
    #       because there can be different endpoints for different operations.
    def endpoint
      return @endpoint if @endpoint

      if service = service_node
        endpoint = service.at_xpath(".//soap11:address/@location", 'soap11' => Wasabi::SOAP_1_1)
        endpoint ||= service.at_xpath(service_node, ".//soap12:address/@location", 'soap12' => Wasabi::SOAP_1_2)
      end

      begin
        @endpoint = URI(URI.escape(endpoint.to_s)) if endpoint
      rescue URI::InvalidURIError
        @endpoint = nil
      end
    end

    private

    def collect_namespaces(*nodes)
      namespaces = {}

      nodes.each do |node|
        node.namespaces.each do |k, v|
          key = k.sub(/^xmlns:/, '')
          namespaces[key] = v
        end
      end

      namespaces.delete('xmlns')
      namespaces
    end

    def schema_nodes
      @schema_nodes ||= begin
        types = @document.at_xpath('/wsdl:definitions/wsdl:types', 'wsdl' => Wasabi::WSDL)
        types ? types.element_children : []
      end
    end

    def service_node
      @document.at_xpath('/wsdl:definitions/wsdl:service', 'wsdl' => Wasabi::WSDL)
    end

  end
end
