Savon [![Build Status](https://secure.travis-ci.org/rubiii/savon.png?branch=master)](http://travis-ci.org/rubiii/savon)
=====

Heavy metal SOAP client

[Documentation](http://savonrb.com) | [RDoc](http://rubydoc.info/gems/savon) |
[Mailing list](https://groups.google.com/forum/#!forum/savonrb) | [Twitter](http://twitter.com/savonrb)

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
client = Savon.client("http://service.example.com?wsdl")

client.wsdl.soap_actions
# => [:create_user, :get_user, :get_all_users]

# execute a SOAP request to call the "getUser" action
response = client.request(:get_user) do
  soap.body = { :id => 1 }
end

response.body
# => { :get_user_response => { :first_name => "The", :last_name => "Hoff" } }
```

Documentation
-------------

Continue reading at [savonrb.com](http://savonrb.com)
