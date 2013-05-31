require 'builder'
require 'savon/body'

class Savon
  class Envelope

    def initialize(operation, options = {})
      @operation = operation
      @message = options[:message]

      @nsid_counter = -1
      @namespaces = {}
    end

    def register_namespace(namespace)
      @namespaces[namespace] ||= create_nsid
    end

    def to_s
      body = Body.new(self, @operation.input).build(@message)
      body = build_rpc_wrapper(body) if rpc_call?

      build_envelope(body)
    end

    private

    def create_nsid
      @nsid_counter += 1
      "lol#{@nsid_counter}"
    end

    #def build_wrapper
      #namespace
    #end

    def build_envelope(body)
      builder = Builder::XmlMarkup.new(indent: 2)

      builder.tag! :env, :Envelope, collect_namespaces do |xml|
        xml.tag!(:env, :Header)
        xml.tag!(:env, :Body) { |xml| xml << body }
      end

      builder.target!
    end

    def build_rpc_wrapper(body)
      name = @operation.name
      namespace = @operation.binding_operation.input[:body][:namespace]
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

      namespaces
    end

  end
end
