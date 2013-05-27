require 'wasabi/schema'
require 'wasabi/message'
require 'wasabi/port_type'
require 'wasabi/binding'
require 'wasabi/service'

class Wasabi
  class Document

    def initialize(document, wsdl)
      @document = document
      @wsdl = wsdl

      @messages, @bindings, @port_types, @services = {}, {}, {}, {}

      collect_sections(
        'message'  => { :collection => @messages,   :container => Message  },
        'binding'  => { :collection => @bindings,   :container => Binding  },
        'portType' => { :collection => @port_types, :container => PortType },
        'service'  => { :collection => @services,   :container => Service  }
      )
    end

    attr_reader :messages, :port_types, :bindings, :services

    def service_name
      @document.root['name']
    end

    def target_namespace
      @document.root['targetNamespace']
    end

    def schemas
      @schemas ||= schema_nodes.map { |node| Schema.new(node, @wsdl) }
    end

    def imports
      imports = []

      @document.root.xpath('wsdl:import', 'wsdl' => Wasabi::WSDL).each do |node|
        location = node['location']
        imports << location if location
      end

      imports
    end

    private

    def collect_sections(mapping)
      section_types = mapping.keys

      @document.root.element_children.each do |node|
        section_type = node.name
        next unless section_types.include? section_type

        node_name = node['name']
        type_mapping = mapping.fetch(section_type)

        collection = type_mapping[:collection]
        container = type_mapping[:container]

        collection[node_name] = container.new(node)
      end
    end

    def schema_nodes
      @schema_nodes ||= schema_nodes! || []
    end

    def schema_nodes!
      root = @document.root
      return [root] if root.name == 'schema'

      types = root.at_xpath('wsdl:types', 'wsdl' => Wasabi::WSDL)
      types.element_children if types
    end

  end
end
