require 'spec_helper'

describe Wasabi do

  [

    :authentication,
    #:bookt,           # TODO: stub imports for bookt
    #:bydexchange,     # TODO: stub imports for bydexchange
    :economic,
    :email_validation,
    #:juniper,         # TODO: fails because of a schema import
    :namespaced_actions,
    :oracle,
    :symbolic_endpoint,
    :telefonkatalogen

  ].each do |fixture_name|

    it "works with #{fixture_name}.wsdl" do
      wsdl = Wasabi.new fixture(fixture_name).read
      wsdl.to_hash
    end

    it "knows the types for #{fixture_name}.wsdl" do
      wsdl = Wasabi.new fixture(fixture_name).read
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

  # fails on jruby due to: https://github.com/sparklemotion/nokogiri/issues/902
  unless RUBY_PLATFORM =~ /java/
    it "works with geotrust.wsdl" do
      wsdl = Wasabi.new fixture(:geotrust).read
      wsdl.to_hash
    end
  end

end
