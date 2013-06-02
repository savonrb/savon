---
title: Version 3
---


Savon 3.0 is currently under development and [available for testing on GitHub](https://github.com/savonrb/savon/tree/version3).
You can add it to your Gemfile right now:

``` bash
gem 'savon', github: 'savonrb/savon', branch: 'version3'
```


What changed?
-------------

Version 3.0 is mainly driven by improvements to the WSDL parser which now supports both WSDL and XML Schema
imports, which means that we now know all the operations and types defined in the WSDL. This enables us to
really benefit from the specification and assist you in new ways.

Version 2.0 exposed and documented dozens of options which were previously scattered around the library
and one of my goals for version 3.0 was to get rid of the useless ones. One common source of confusion
and problems is that Savon always worked with and without a WSDL and because the parser was not very good,
it didn't always make sense to use a WSDL. The new parser already works great and it only gets better
if it's being used. That's why this version requires and relies on a WSDL document which removes the
need for quite a few options.

Requests are now based on a new type system based on the XML Schema, which means we're getting rid of
[Gyoku](https://github.com/savonrb/gyoku) and [Nori](https://github.com/savonrb/nori). Those libraries work
great in scenarios where you don't have to care about namespaces, types and attributes. Unfortunately, in
order to "get it right", we need to care about that.

Another big set of options was passed directly to [HTTPI](https://github.com/savonrb/httpi) and while Savon
has to execute HTTP requests, it only cares about the HTTP body and headers. This library doesn't need to
know much about HTTP and it certainly doesn't need to complicate the situation by relying on HTTPI.
Version 3.0 does not depend on HTTPI, but uses an adapter class based on
[HTTPClient](https://github.com/nahi/httpclient) which you can extend to use your favourite HTTP client
and to handle more complicated HTTP work.

Last but now least, I merged the code for what was planned to be released as Wasabi 4.0 into Savon.
This was really just an experiment, but merging the two libraries was super easy and removed quite a few
duplicated fixtures and specs. So all the code and tests for this are back in one repository, which
is good because it removes the need for me to coordinate releases between all those libraries.


New features
------------

* Version 3.0 requires Ruby 1.9 or higher. Yes, I'm considering this a feature!
* It does not have any opinions on HTTP and allows you to extend it to work in your scenario.
* It is based on specifications and validates against many real world WSDL documents.
* It is way faster than ever before, while now parsing all elements.
* It properly separates operations by service and port.
* It supports WSDL and XML Schema imports.
* It knows the input, output and fault message types, namespaces, etc.
* It can create example requests for you.

This list is probably far from complete.


Getting started
---------------

Instantiate Savon with a URL or the path to a local WSDL document.

``` ruby
client = Savon.new('http://example.com?wsdl')
```

On creation, Savon parses the document and resolves any imports. The interface is similar to the
previous version, but since this version properly separates operations by service and port, you
now need to specify the service and port to use.

In order to allow you to decide on the service and port, Savon exposes them along with their
namespace and endpoint, where the namespace indicates the SOAP version to use.

``` ruby
client.services
```

For many services, this will return a Hash with a single service with a single port, but some
services separate their operations by service and port so you have to knows about them. Here
is an example for a WSDL with a single service and port.

``` ruby
{
  # Name of the service.
  AuthenticationService: {
    ports: {

      # Name of the port.
      AuthenticationPort: {

        # SOAP 1.1 namespace.
        type: 'http://schemas.xmlsoap.org/wsdl/soap/',

        # SOAP endpoint.
        location: 'http://example.com/AuthenticationService'
      }
    }
  }
}
```

Exposing the services and ports as a Hash also allows you to programatically walk through the
services, ports and their operations.

With this, you can get a list of Operations for a service and port:

``` ruby
service_name = :AuthenticationService
port_name    = :AuthenticationPort

client.operations(service_name, port_name)
```

and more importantly, you can ask for an Operation:

``` ruby
service_name   = :AuthenticationService
port_name      = :AuthenticationPort
operation_name = :authenticate

operation = client.operation(service_name, port_name, operation_name)
```

An Operation behaves similar to how it behaved in version 2. It knows everything about a
specific operation and can be configured to call it. This is what I'm working on right
now, so things might change and I'd appreciate your feedback!

There's also a shortcut for calling an Operation.

``` ruby
service_name   = :AuthenticationService
port_name      = :AuthenticationPort
operation_name = :authenticate
options        = {}

response = client.call(service_name, port_name, operation_name, options)
```

...


Operations
----------

...
