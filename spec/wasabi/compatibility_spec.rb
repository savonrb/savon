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
      wsdl.inspect.to_hash
    end

  end

  # fails on jruby due to: https://github.com/sparklemotion/nokogiri/issues/902
  unless RUBY_PLATFORM =~ /java/
    it "works with geotrust.wsdl" do
      wsdl = Wasabi.new fixture(:geotrust).read
      wsdl.inspect.to_hash
    end
  end

end
