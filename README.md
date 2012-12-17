Savon [![Build Status](https://secure.travis-ci.org/savonrb/savon.png?branch=version2)](http://travis-ci.org/savonrb/savon)
=====

Heavy metal SOAP client

[Documentation](http://savonrb.com) | [RDoc](http://rubydoc.info/gems/savon) |
[Mailing list](https://groups.google.com/forum/#!forum/savonrb) | [Twitter](http://twitter.com/savonrb)

Version 2
---------

Savon 2.0 is almost feature-complete and I would really appreciate your feedback!  
To get started, add the following line to your Gemfile:

``` ruby
gem "savon", github: "savonrb/savon", branch: "version2"
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

Continue reading at [savonrb.com](http://savonrb.com/version2.html)
