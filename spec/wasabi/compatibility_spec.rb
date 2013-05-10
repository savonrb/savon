require 'spec_helper'

describe Wasabi do

  [

    :authentication,
    #:bookt,           # TODO: stub imports for bookt
    #:bydexchange,     # TODO: stub imports for bydexchange
    :economic,
    :email_validation,
    :geotrust,
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

end
