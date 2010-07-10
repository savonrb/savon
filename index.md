---
title: Heavy metal Ruby SOAP client
layout: default
---

Introduction to Savon
=====================

Savon is a SOAP client library for Ruby. It aims to make simple tasks easy and hard tasks possible. Before using it, you should read the documentation and make yourself familiar with [SOAP](http://www.w3.org/TR/soap/) itself, [WSDL documents](http://www.w3.org/TR/wsdl) and tools like [soapUI](http://www.eviware.com).

Table of contents
-----------------

* [Installation](#installation)
* [Getting started](#getting_started)
* [Working with a WSDL](#working_with_a_wsdl)
* [Executing a SOAP request](#executing_a_soap_request)
* [SOAP request customization](#soap_request_customization)
  * [SOAP version](#soap_version)
  * [SOAP envelope](#soap_envelope)
  * [SOAP header](#soap_header)
  * [SOAP body](#soap_body)

Installation
------------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

    $ gem install savon

Getting started
---------------

The primary interface for Savon is the `Savon::Client` object. It contains the `#request` method for executing SOAP requests while also serving as a wrapper for accessing the SOAP, WSDL and Request objects.

Assuming you have access to a WSDL, you need to instantiate a `Savon::Client` passing in the location of the WSDL:

{% highlight ruby %}
client = Savon::Client.new :wsdl => "http://example.com/UserService?wsdl" # remote
client = Savon::Client.new :wsdl => "../wsdl/user_service.xml" # local
{% endhighlight %}

Even though using a WSDL comes with some advantages, loading and parsing the WSDL might take quite some time. So if you don't have or don't want to use a WSDL, you can directly access the SOAP endpoint instead. In this case, you need to pass in the URI of the SOAP endpoint and the target namespace of the service:

{% highlight ruby %}
client = Savon::Client.new(
  :endpoint => "http://example.com/UserService",
  :namespace => "http://users.example.com"
)
{% endhighlight %}

You can also use the WSDL and overwrite its SOAP endpoint:

{% highlight ruby %}
client = Savon::Client.new(
  :wsdl => "http://example.com/UserService?wsdl",
  :endpoint => "http://localhost:8080/UserService"
)
{% endhighlight %}

And in case you're using a proxy server to access the service, you can specify that as well:

{% highlight ruby %}
client = Savon::Client.new(
  :wsdl => "http://example.com/UserService?wsdl",
  :proxy => "http://proxy.example.com"
)
{% endhighlight %}

Working with a WSDL
-------------------

If you decided to use a WSDL, you can now check to see what it knows about your service:

{% highlight ruby %}
client.wsdl.soap_actions  # => [:add_user, :get_user, :get_all_users]
client.wsdl.endpoint      # => "http://example.com/UserService"
client.wsdl.namespace     # => "http://users.example.com"
{% endhighlight %}

Currently, the WSDL parser is still pretty basic and in some cases it might not be able to get the correct information. So it's recommended that you check the state of the `Savon::WSDL` object.

### SOAP actions

Savon maps the SOAP actions of your service to snake_case Symbols, because that just feels more natural. You can inspect the mapping via:

{% highlight ruby %}
client.wsdl.operations
# => { :add_user => { :action => "addUser", :input => "addUserRequest" }, ... }
{% endhighlight %}

As you can see from this example, the Hash contains the value for the `SOAPAction` HTTP header and the name of the input tag (the first tag inside the soap:Body element). So if the mapping worked out as it should, you can forget about these details and just remember that the SOAP action you're going to call is a snake_case Symbol.

If the mapping does not contain the values you expected, you can either overwrite them when executing a SOAP request or simply not use the WSDL.

Executing a SOAP request
------------------------

To execute a SOAP request, you use the `#request` method of your `Savon::Client`, passing in name of the SOAP action you want to call:

{% highlight ruby %}
client.request :get_all_users
# => <getAllUsers></getAllUsers>
{% endhighlight %}

Notice that if you're working with a WSDL, Savon will register the `xmlns:wsdl` namespace for you. In order to namespace the SOAP input tag, you pass in both the namespace and action:

{% highlight ruby %}
client.request :wsdl, :get_all_users
# => <wsdl:getAllUsers></wsdl:getAllUsers>
{% endhighlight %}

You can also add a Hash of attributes for the input tag as the last argument:

{% highlight ruby %}
client.request :get_all_users, "xmlns:doc" => "http://doc.example.com"
# => <getAllUsers xmlns:doc="http://doc.example.com"></getAllUsers>
{% endhighlight %}

When you're not working with a WSDL, Savon does not know anything about the SOAP actions of your service. So by convention, if you pass in the action as a snake_case Symbol, it gets converted to lowerCamelCase. But don't worry. If you pass in a String instead of a Symbol, Savon will use it without converting:

{% highlight ruby %}
client.request "GetAllUsers"
# => <GetAllUsers></GetAllUsers>
{% endhighlight %}

SOAP request customization
--------------------------

When executing a SOAP request, `Savon::Client#request` also accepts a block in which you have access to the SOAP, WSDL and Request objects. This block is the place for you to set the payload, change HTTP headers, specify authentication credentials, etc.

<div class="warn">Due to the evaluation of the block, you can use local variables and methods, but you can not use instance variables inside it!</div>

Before going into the details, let's take a look at an example request. The comments should help you understand what the documentation is talking about.

    POST http://example.com/UserService HTTP/1.1
    Accept-Encoding: gzip,deflate                                         # HTTP header
    Content-Type: text/xml;charset=UTF-8
    SOAPAction: "getUser"                                                 # SOAP action
    
    <soap:Envelope                                                        # SOAP envelope
        xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"            # Namespaces
        xmlns:wsdl="http://users.example.com">
      <soap:Header/>                                                      # SOAP header
      <soap:Body>                                                         # SOAP body
        <wsdl:getUser>                                                    # Input tag
          <id>123</id>                                                    # Payload
        </wsdl:getUser>
      </soap:Body>
    </soap:Envelope>

### SOAP version

Savon by default expects your service to be based on SOAP 1.1. You can use `Savon::SOAP#version` to set the version to SOAP 1.2:

{% highlight ruby %}
client.request(:get_user) { soap.version = 2 }
{% endhighlight %}

Changing the SOAP version affects the `xmlns:soap` namespace as well as error handling details.

### SOAP envelope

#### Namespaces

Savon defines the `xmlns:soap` namespace for the current SOAP version. It also defines the `xmlns:wsdl` namespace if you're using a WSDL. You can define additional namespaces using the `Savon::SOAP#namespaces` method which returns a Hash:

{% highlight ruby %}
client.request :get_user do
  soap.namespaces["xmlns:custom"] = "http://custom.example.com"
end
# => <soap:Envelope
# =>   xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
# =>   xmlns:custom="http://custom.example.com">
{% endhighlight %}

#### XML (or: I don't need your help)

If you don't want Savon to create any XML and just handle the requests, you can pass an object responding to `to_s` to the `Savon::SOAP#xml` method:

{% highlight ruby %}
client.request(:get_user) { soap.xml = "<my:Envelope>empty</my:Envelope>" }
# => <my:Envelope>empty</my:Envelope>
{% endhighlight %}

### SOAP header

...

### SOAP body

XML is verbose and boring. And since basic XML can be represented as a Hash ... well, just take a look at the following example:

{% highlight ruby %}
client.request(:get_user) { soap.body = { :user_id => 123 } }
# => <getUser><userId>123</userId></getUser>
{% endhighlight %}

You can pass a Hash to `Savon::SOAP#body` and it will be converted to XML via `Hash#to_soap_xml`. Notice that by convention, Hash key Symbols are converted to lowerCamelCase. But again, you can use Hash key Strings which will not be converted.

{% highlight ruby %}
client.request(:get_user) { soap.body = { "UserID" => 123 } }
# => <getUser><UserID>123</UserID></getUser>
{% endhighlight %}

This works great for simple data, but can also be used to generate more complex XML.

#### Element order

Some services require XML elements to be in a specific order. If you're not working with Ruby 1.9 by now, that might be a problem. One solution is to specify the exact order of elements in an Array under the `:order!` key:

{% highlight ruby %}
client.request :add_user do
  soap.body = {
    :user => {
      :name => "Eve",
      :email => "eve@example.com",
      :order! => [:name, :email]
    }
  }
end
# => <addUser>
# =>   <user>
# =>     <name>Eve</name>
# =>     <email>eve@example.com</email>
# =>   </user>
# => </addUser>
{% endhighlight %}

#### Attributes

Savon also lets you attach attributes through a Hash under the `:attributes!` key:

{% highlight ruby %}
client.request :add_user do
  soap.body = {
    :user => {
      :name => "Eve",
      :contact => "eve@example.com",
      :attributes! => { :contact => { "type" => "email" } }
    }
  }
end
# => <addUser>
# =>   <user>
# =>     <name>Eve</name>
# =>     <contact type="email">eve@example.com</contact>
# =>   </user>
# => </addUser>
{% endhighlight %}

#### XML (aka the hard way)

`Savon::SOAP#body` also accepts any object that is not a Hash and responds to `to_s`. So you can use anything from a simple String to any kind of object returning a String of XML:

{% highlight ruby %}
client.request(:get_user) { soap.body = "<id>123</id>" }
# => <getUser><id>123</id></getUser>
{% endhighlight %}
