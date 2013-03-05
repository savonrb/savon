Savon
=======

Heavy metal SOAP client

[Documentation](http://savonrb.com) | [RDoc](http://rubydoc.info/gems/savon) |
[Mailing list](https://groups.google.com/forum/#!forum/savonrb) | [Twitter](http://twitter.com/savonrb)

[![Build Status](https://secure.travis-ci.org/savonrb/savon.png)](http://travis-ci.org/savonrb/savon) [![Gem Version](https://badge.fury.io/rb/savon.png)](http://badge.fury.io/rb/savon)


Installation
------------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

```
$ gem install savon
```


Introduction
------------

``` ruby
require 'savon'

# create a client for the service
client = Savon.client(wsdl: "http://service.example.com?wsdl")

client.operations
# => [:find_user, :list_users]

# call the 'getUser' operation
response = client.call(:find_user, message: { id: 42 })

response.body
# => { find_user_response: { id: 42, name: 'Hoff' } }
```


Documentation
-------------

Continue reading at [savonrb.com](http://savonrb.com)
