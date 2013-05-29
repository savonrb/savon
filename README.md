# Wasabi

Wasabi is a simple WSDL parser written in Ruby and extracted from the
[Savon](https://github.com/savonrb/savon) SOAP client.

[![Build Status](https://secure.travis-ci.org/savonrb/wasabi.png)](http://travis-ci.org/savonrb/wasabi)
[![Gem Version](https://badge.fury.io/rb/wasabi.png)](http://badge.fury.io/rb/wasabi)
[![Code Climate](https://codeclimate.com/github/savonrb/wasabi.png)](https://codeclimate.com/github/savonrb/wasabi)
[![Coverage Status](https://coveralls.io/repos/savonrb/wasabi/badge.png?branch=master)](https://coveralls.io/r/savonrb/wasabi)


Wasabi 4.0 is under active development and currently only available via GitHub.  
To give it a try, you can add it to your Gemfile.

``` ruby
gem 'wasabi', github: 'savonrb/wasabi'
```

Since Wasabi 4.0 supports both WSDL and XML Schema imports, it needs some HTTP client to resolve these imports.
Wasabi is not coupled to any particular HTTP client, but requires you to give it an object which responds to
`#get(url)` and returns the raw HTTP response body as a String.

This allows you to use any HTTP client and easily swap it out for testing. Here's an example for the
[HTTPClient](https://github.com/nahi/httpclient) library:

``` ruby
require 'httpclient'

class MyClient

  def initialize
    @client = HTTPClient.new
  end

  def get(url)
    @client.get_content(url)
  end

end
```

With that defined, you can instantiate Wasabi with a URL or the local path to a WSDL document
plus an instance of your HTTP object.

``` ruby
wsdl = Wasabi.new('http://example.com?wsdl', MyClient.new)
```

Get the name of the service.

``` ruby
wsdl.service_name
```

Get the target namespace of the document.

``` ruby
wsdl.target_namespace
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
operation.soap_action
operation.endpoint
operation.input
```
