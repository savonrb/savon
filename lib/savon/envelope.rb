require 'builder'
require 'savon/message'

class Savon
  class Envelope

    NSID = 'lol'

    def initialize(operation, header, body)
      @logger = Logging.logger[self]

      @operation = operation
      @header = header || {}
      @body = body || {}

      @nsid_counter = -1
      @namespaces = {}
    end

    def register_namespace(namespace)
      @namespaces[namespace] ||= create_nsid
    end

    def to_s
      build_envelope(build_header, build_body)
    end

    private

    def create_nsid
      @nsid_counter += 1
      "#{NSID}#{@nsid_counter}"
    end

    def build_header
      return "" if @header.empty?
      Message.new(self, @operation.header_parts).build(@header)
    end

    def build_body
      return "" if @body.empty?
      body = Message.new(self, @operation.body_parts).build(@body)

      if rpc_call?
        build_rpc_wrapper(body)
      else
        body
      end
    end

    def build_envelope(header, body)
      builder = Builder::XmlMarkup.new(indent: 2)

      builder.tag! :env, :Envelope, collect_namespaces do |xml|
        xml.tag!(:env, :Header) { |xml| xml << header }
        xml.tag!(:env, :Body) { |xml| xml << body }
      end

      builder.target!
    end

    def build_rpc_wrapper(body)
      name = @operation.name
      namespace = @operation.binding_operation.input_body[:namespace]
      nsid = register_namespace(namespace) if namespace

      tag = [nsid, name].compact.join(':')

      '<%{tag}>%{body}</%{tag}>' % { tag: tag, body: body }
    end

    def rpc_call?
      @operation.binding_operation.style == 'rpc'
    end

    def collect_namespaces
      # registered namespaces
      namespaces = @namespaces.each_with_object({}) { |(namespace, nsid), memo|
        memo["xmlns:#{nsid}"] = namespace
      }

      # envelope namespace
      namespaces['xmlns:env'] = case @operation.soap_version
        when '1.1' then 'http://schemas.xmlsoap.org/soap/envelope/'
        when '1.2' then 'http://www.w3.org/2003/05/soap-envelope'
      end

      namespaces
    end

  end
end
