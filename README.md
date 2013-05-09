# Wasabi

Wasabi is a simple WSDL parser written in Ruby and extracted from the
[Savon](https://github.com/savonrb/savon) SOAP client.

[![Build Status](https://secure.travis-ci.org/savonrb/wasabi.png)](http://travis-ci.org/savonrb/wasabi)
[![Gem Version](https://badge.fury.io/rb/wasabi.png)](http://badge.fury.io/rb/wasabi)
[![Code Climate](https://codeclimate.com/github/savonrb/wasabi.png)](https://codeclimate.com/github/savonrb/wasabi)
[![Coverage Status](https://coveralls.io/repos/savonrb/wasabi/badge.png?branch=master)](https://coveralls.io/r/savonrb/wasabi)


Wasabi is available through [Rubygems](http://rubygems.org/gems/wasabi) and can be installed via:

```
$ gem install wasabi
```

or add it to your Gemfile like this:

```
gem 'wasabi'
```

**Attention:** This targets the code on GitHub master.  
Here is the [README for the latest released version (v3.1.0)](https://github.com/savonrb/wasabi/blob/v3.1.0/README.md).


``` ruby
# Instantiate Wasabi with a URL or the path to a WSDL document.
wsdl = Wasabi.new('http://example.com?wsdl')

# Get the name of the service.
wsdl.service_name  # => 'ExampleWebService'

# Get the SOAP endpoint of the service.
# This will be moved to the operation soon.
wsdl.endpoint  # => 'http://v1.example.com'

# Get the target namespace of the document.
wsdl.target_namespace  # => 'http://v1.example.com'

# Get the namespaces.
wsdl.namespaces  # => { 'wsdl' => 'http://schemas.xmlsoap.org/wsdl/', ... }

# Get an operation by name.
# This will be changed to use the original operation name.
wsdl.operation(:authenticate)  # => '<Wasabi::Operation ...>'
```
