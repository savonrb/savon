Savon
=====

Heavy metal Ruby SOAP client

[Guide](http://rubiii.github.com/savon) | [Rubydoc](http://rubydoc.info/gems/savon) | [Wishlist](http://savon.uservoice.com) | [Bugs](http://github.com/rubiii/savon/issues)

Installation
------------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

    $ gem install savon

Usage example
-------------

    # Setting up a Savon::Client representing a SOAP service.
    client = Savon::Client.new do
      wsdl.document = "http://service.example.com?wsdl"
    end

    client.wsdl.soap_actions
    # => [:create_user, :get_user, :get_all_users]

    # Executing a SOAP request to call a "findUser" action.
    response = client.request :find_user do
      soap.body = { :id => 1 }
    end

    response.to_hash
    # => { :get_user_response => { :first_name => "The", :last_name => "Hoff" } }

Excited to learn more?
----------------------

Then you might want to go ahead and read the [Savon Guide](http://rubiii.github.com/savon).
