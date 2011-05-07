Savon [![Build Status](http://travis-ci.org/rubiii/savon.png)](http://travis-ci.org/rubiii/savon)
=====

Heavy metal Ruby SOAP client

[Documentation](http://savonrb.com) | [RDoc](http://rubydoc.info/gems/savon) |
[Mailing list](http://groups.google.com/group/savon-soap) | [Twitter](http://twitter.com/savonrb)

Installation
------------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

```
$ gem install savon
```

Basic workflow
--------------

``` ruby
# Setting up a Savon::Client representing a SOAP service.
client = Savon::Client.new "http://service.example.com?wsdl"

client.wsdl.soap_actions
# => [:create_user, :get_user, :get_all_users]

# Executing a SOAP request to call a "getUser" action.
response = client.request :get_user do
  soap.body = { :id => 1 }
end

response.to_hash
# => { :get_user_response => { :first_name => "The", :last_name => "Hoff" } }
```

Ready for more?
---------------

[Go ahead and read the official documentation](http://savonrb.com).
