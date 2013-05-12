require 'uri'

class Wasabi
  class DocumentCollection
    include Enumerable

    def initialize
      @documents = []
    end

    def <<(document)
      @documents << document
    end

    def each(&block)
      @documents.each(&block)
    end

    def service_name
      @service_name ||= first.service_name
    end

    def target_namespace
      @target_namespace ||= first.target_namespace
    end

    def target_namespace
      @target_namespace ||= first.target_namespace
    end

    def namespaces
      @namespaces ||= inject({}) { |memo, document| memo.merge(document.namespaces) }
    end

    def messages
      @messages ||= collect_sections { |document| document.messages }
    end

    def port_types
      @port_types ||= collect_sections { |document| document.port_types }
    end

    def bindings
      @bindings ||= collect_sections { |document| document.bindings }
    end

    def services
      @services ||= collect_sections { |document| document.services }
    end

    private

    def collect_sections
      result = {}

      each do |document|
        sections = yield document
        result.merge! sections
      end

      result
    end

  end
end
