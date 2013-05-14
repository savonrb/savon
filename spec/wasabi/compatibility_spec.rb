require 'spec_helper'

describe Wasabi do

  [

    :authentication,
    #:bookt,           # TODO: stub imports for bookt
    #:bydexchange,     # TODO: stub imports for bydexchange
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
      wsdl = Wasabi.new fixture(fixture_name).read

      wsdl.service_name
      wsdl.target_namespace
      wsdl.namespaces

      wsdl.documents.messages.each do |_, message|
        message.parts
      end

      wsdl.documents.bindings.each do |_, binding|
        binding.operations
      end

      wsdl.documents.port_types.each do |_, port_type|
        port_type.operations
      end

      wsdl.documents.services.each do |_, service|
        service.ports
      end

      wsdl.schemas.each do |schema|

        schema.elements.each do |_, type|
          type.children
        end

        schema.complex_types.each do |_, type|
          type.children
        end

        schema.simple_types.each do |_, type|
          type.children
        end

      end
    end

  end

end
