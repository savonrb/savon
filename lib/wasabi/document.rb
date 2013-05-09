require 'wasabi/schema'
require 'wasabi/legacy_operation_parser'

class Wasabi
  class Document

    def initialize(document, wsdl)
      @document = document
      @wsdl = wsdl
    end

    def service_name
      @document.root['name']
    end

    def target_namespace
      @document.root['targetNamespace']
    end

    def namespaces
      @namespaces ||= collect_namespaces(@document, *schema_nodes)
    end

    def schemas
      @schemas ||= schema_nodes.map { |node| Schema.new(node, @wsdl) }
    end

    def imports
      imports = []

      @document.xpath('/wsdl:definitions/wsdl:import', 'wsdl' => Wasabi::WSDL).each do |node|
        location = node['location']
        imports << location if location
      end

      imports
    end

    def operations
      @operations ||= LegacyOperationParser.new(@document).operations
    end

    def service_node
      @document.at_xpath('/wsdl:definitions/wsdl:service', 'wsdl' => Wasabi::WSDL)
    end

    private

    def schema_nodes
      @schema_nodes ||= begin
        types = @document.at_xpath('/wsdl:definitions/wsdl:types', 'wsdl' => Wasabi::WSDL)
        types ? types.element_children : []
      end
    end

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

  end
end
