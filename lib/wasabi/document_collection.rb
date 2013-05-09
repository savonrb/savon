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

    def operations
      @operations ||= inject({}) { |memo, document| memo.merge(document.operations) }
    end

    # TODO: this works for now, but it should be moved into the Operation,
    #       because there can be different endpoints for different operations.
    def endpoint
      return @endpoint if @endpoint

      if service = first.service_node
        endpoint = service.at_xpath(".//soap11:address/@location", 'soap11' => Wasabi::SOAP_1_1)
        endpoint ||= service.at_xpath(service_node, ".//soap12:address/@location", 'soap12' => Wasabi::SOAP_1_2)
      end

      begin
        @endpoint = URI(URI.escape(endpoint.to_s)) if endpoint
      rescue URI::InvalidURIError
        @endpoint = nil
      end
    end

  end
end
