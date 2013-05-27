require 'spec_helper'

describe Wasabi do

  [

    :authentication,
    #:bookt,           # TODO: stub imports for bookt
    #:bydexchange,     # TODO: stub imports for bydexchange
    :crowd,
    :data_exchange,
    :economic,
    :email_validation,
    #:geotrust,        # fails on jruby due to: https://github.com/sparklemotion/nokogiri/issues/902
    #:juniper,         # TODO: fails because of a schema import
    :namespaced_actions,
    :oracle,
    :symbolic_endpoint,
    :telefonkatalogen

  ].each do |fixture_name|

    it "works with #{fixture_name}.wsdl" do
      wsdl = Wasabi.new fixture("#{fixture_name}.wsdl").read

      wsdl.service_name
      wsdl.target_namespace

      wsdl.schemas.each do |schema|

        schema.elements.each do |_, type|
          type.collect_child_elements
        end

        schema.complex_types.each do |_, type|
          type.collect_child_elements
        end

        schema.simple_types.each do |_, type|
          type.collect_child_elements
        end

      end

      wsdl.documents.messages.each do |_, message|
        message.parts
      end

      wsdl.documents.bindings.each do |_, binding|
        binding.operations
      end

      wsdl.documents.port_types.each do |_, port_type|
        port_type.operations
      end

      wsdl.documents.services.each do |service_name, service|
        service.ports.each do |port_name, port|
          wsdl.operations(service_name, port_name).each do |_, operation|

            operation.input

          end
        end
      end
    end

  end
end
