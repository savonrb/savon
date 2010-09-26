Savon
=====

Heavy metal Ruby SOAP client.

[Wishlist](http://savon.uservoice.com) | [Bugs](http://github.com/rubiii/savon/issues) | [Docs](http://rubydoc.info/gems/savon)

Installation
------------

The gem is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

    $ gem install savon

Savon expects you to be familiar with SOAP, WSDL and tools like soapUI.

Instantiate a client
--------------------

Instantiate Savon::Client, passing in the WSDL of your service.

    client = Savon::Client.new :wsdl => "http://example.com/UserService?wsdl"

For production, it is highly recommended to not use Savon::WSD::DocumentL. Information on {how to disable the WSDL}[http://savon.rubiii.com/docs/latest/classes/Savon/WSDL.html].

Calling a SOAP action
---------------------

Assuming your service applies to the defaults, you can now call any available SOAP action.

    response = client.get_all_users

Savon lets you call SOAP actions using snake_case, because even though they will propably be written in lowerCamelCase or CamelCase, it just feels much more natural.

The WSDL object
---------------

Savon::WSDL::Document represents the WSDL of your service, including information like the namespace URI and available SOAP actions.

    client.wsdl.soap_actions
    => [:get_all_users, :get_user_by_id, :user_magic]

The SOAP object
---------------

Savon::SOAP::XML represents the SOAP request. Pass a block to your SOAP call and the SOAP object is passed to it as the first argument. The object allows setting the SOAP version, header, body and namespaces per request.

    response = client.get_user_by_id { |soap| soap.body = { :id => 666 } }

The WSSE object
---------------

Savon::WSSE represents WSSE authentication. Pass a block to your SOAP call and the WSSE object is passed to it as the second argument. The object allows setting the WSSE username, password and whether to use digest authentication.

    response = client.get_user_by_id do |soap, wsse|
      wsse.username = "gorilla"
      wsse.password = "secret"
      soap.body = { :id => 666 }
    end

The Request object
------------------

Savon uses [HTTPI](http://rubygems.org/gems/httpi) to execute HTTP requests. You can access the HTTPI::Request object to specify HTTP request headers, authentication credentials and more. Here's an example:

    # Sets the Accept-encoding header.
    client.request.gzip

The Response object
-------------------

Savon::SOAP::Response represents the HTTP and SOAP response. It contains and raises errors in case of an HTTP error or SOAP fault (unless disabled). Also you can get the response as XML (for parsing it with an XML library) or translated into a Hash.

== HTTP errors and SOAP faults

Savon raises a Savon::SOAPFault in case of a SOAP fault and a Savon::HTTPError in case of an HTTP error.
More information: {Errors}[http://savon.rubiii.com/docs/latest/classes/Savon/Response.html]

== Logging

Savon logs each request and response to STDOUT. But there are a couple of options to change the default behavior.
More information: {Logging}[http://savon.rubiii.com/docs/latest/classes/Savon/Request.html]
