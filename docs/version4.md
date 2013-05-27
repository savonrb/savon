---
title: Version 4
---


Wasabi 4.0 is under active development and currently only available via GitHub.  
To give it a try, just add it to your Gemfile.

``` ruby
gem 'wasabi', github: 'savonrb/wasabi'
```

You can also find a summary of the changes in the
[Changelog](https://github.com/savonrb/wasabi/blob/master/CHANGELOG.md).


The big rewrite
---------------

Wasabi 4.0 is based on everything I learned while helping people talk to SOAP services using Ruby for the past five years.
The goal for this is to follow the specifications as close as possible while verifying them against real world services.



#### Services and endpoints

"A WSDL document defines [services as collections of network endpoints](http://www.w3.org/TR/wsdl#_introduction), or ports".
Multiple services, multiple ports. Endpoint URLs are defined per port and each port references a binding which in turn
defines a set of operations. This means you need to know about the services and ports defined by the WSDL.

``` xml
<wsdl:service name="AuthenticationService">
  <wsdl:port binding="tns:AuthenticationServiceBinding" name="AuthenticationServicePort">
     <soap:address location="http://example.com/validation/1.0/AuthenticationService"/>
  </wsdl:port>
</wsdl:service>
```

Create a new Wasabi instance with a URL or a path to a local WSDL document.

``` ruby
wsdl = Wasabi.new('http://example.com?wsdl')
```

Wasabi also accepts an optional `HTTPI::Request` object which it uses to fetch remote WSDL files and resolve imports.
This allows you to [pre-configure any HTTP request](http://httpirb.com/#options).

``` ruby
request = HTTPI::Request.new
request.proxy = 'http://localhost:8447'

wsdl = Wasabi.new('example.wsdl', request)
```

Now you can call the `#services` method for a summary of the services and ports defined by the WSDL.

``` ruby
wsdl.services
```

This returns a list of service and ports along with information about the port's type and location.
The type is a namespace which in this example indicates a SOAP 1.1 port. The location is the actual
location of the service.

Remember that there could be multiple services with multiple ports which each reference a different
set of operations. Also, Wasabi currently only returns SOAP 1.1 and 1.2 services and ports.
Selection the proper ports should probably be left to any client library, but this is just how
it curently works.

``` ruby
{
  'ExampleService'  => {
    :ports          => {
      'ExamplePort' => {
        :type       => 'http://schemas.xmlsoap.org/wsdl/soap/',
        :location   => 'http://example.com'
      }
    }
  }
}
```


#### Operations

Knowing the name of a service and port gives you access to its operations.

``` ruby
operations = wsdl.operations('ExampleService', 'ExamplePort')
```

This returns a list of operation names and objects which can be asked anything needed to call this operation.

``` ruby
{
  'someOperation'    => <Wasabi::Operation>,
  'anotherOperation' => <Wasabi::Operation>
}
```

There's also the `#operation` shortcut method which accepts the name of a service and port and the
name of an operation to get a single operation object.

``` ruby
operation = wsdl.operation('ExampleService', 'ExamplePort', 'someOperation')
```

Operations should know everything you need to create an HTTP request and call the operation.

``` ruby
operation.name         # => 'authenticate'
operation.nsid         # => 'tns'
operation.input        # => 'authenticate'
operation.soap_action  # => 'urn:authenticate'
operation.endpoint     # => 'http://v1.example.com'
```
