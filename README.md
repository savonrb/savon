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
require "savon"

# create a client for your SOAP service
client = Savon.client(wsdl: "http://service.example.com?wsdl")

client.operations
# => [:create_user, :get_user, :get_all_users]

# execute a SOAP request to call the "getUser" action
response = client.call(:get_user) do
  message(user_id: 1)
end

response.body
# => { :get_user_response => { :first_name => "The", :last_name => "Hoff" } }
```


Documentation
-------------

Continue reading at [savonrb.com](http://savonrb.com)
