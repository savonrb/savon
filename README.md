# Savon

Heavy metal SOAP client

[Documentation](http://savonrb.com) | [RDoc](http://rubydoc.info/gems/savon) |
[Mailing list](https://groups.google.com/forum/#!forum/savonrb) | [Twitter](http://twitter.com/savonrb)

[![Build Status](https://secure.travis-ci.org/savonrb/savon.png)](http://travis-ci.org/savonrb/savon)
[![Gem Version](https://badge.fury.io/rb/savon.png)](http://badge.fury.io/rb/savon)
[![Code Climate](https://codeclimate.com/github/savonrb/savon.png)](https://codeclimate.com/github/savonrb/savon)


## Installation

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

```
$ gem install savon
```

or add it to your Gemfile like this:

```
gem 'savon', '~> 2.1.0'
```


## Usage example

``` ruby
require 'savon'

# create a client for the service
client = Savon.client(wsdl: 'http://service.example.com?wsdl')

client.operations
# => [:find_user, :list_users]

# call the 'findUser' operation
response = client.call(:find_user, message: { id: 42 })

response.body
# => { find_user_response: { id: 42, name: 'Hoff' } }
```

For more examples, you should check out the [integration tests](https://github.com/savonrb/savon/tree/master/spec/integration).


## Documentation

Please make sure to read the documentation for your version:

* [Version 2](http://savonrb.com/version2.html)
* [Version 1](http://savonrb.com)

And if you find any problems with it or if you think something's missing,  
feel free to [help out and improve the documentation](https://github.com/savonrb/savonrb.com).
