# Wasabi

Wasabi is a simple WSDL parser written in Ruby and extracted from the
[Savon](https://github.com/savonrb/savon) SOAP client.

[![Build Status](https://secure.travis-ci.org/savonrb/wasabi.png)](http://travis-ci.org/savonrb/wasabi)
[![Gem Version](https://badge.fury.io/rb/wasabi.png)](http://badge.fury.io/rb/wasabi)
[![Code Climate](https://codeclimate.com/github/savonrb/wasabi.png)](https://codeclimate.com/github/savonrb/wasabi)
[![Coverage Status](https://coveralls.io/repos/savonrb/wasabi/badge.png?branch=master)](https://coveralls.io/r/savonrb/wasabi)


Wasabi 4.0 is under active development and currently only available via GitHub.  
To give it a try, just add it to your Gemfile.

``` ruby
gem 'wasabi', github: 'savonrb/wasabi'
```

Instantiate Wasabi with a URL or the path to a WSDL document.

``` ruby
wsdl = Wasabi.new('http://example.com?wsdl')
```

Get the name of the service.

``` ruby
wsdl.service_name
```

Get the target namespace of the document.

``` ruby
wsdl.target_namespace
```

Get the namespaces.

``` ruby
wsdl.namespaces
```

Get a summary of the services and ports.

``` ruby
wsdl.services
```

Get a list of operations by service and port.

``` ruby
wsdl.operations('ExampleService', 'ExamplePort')
```

Get a single operation by service, port and operation name.

``` ruby
wsdl.operation('ExampleService', 'ExamplePort', 'authenticate')
```

Query the operation for its information.

``` ruby
operation.name
operation.nsid
operation.input
operation.soap_action
operation.endpoint
```

Inspect the service. Returns a big Hash with useful
information about the service. Very helpful for debugging.

``` ruby
wsdl.inspect.to_hash
```
