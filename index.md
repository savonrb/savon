---
title: Heavy metal Ruby SOAP client
layout: default
---

Savon Guide
===========

Savon is a SOAP client library for Ruby. It's goal is to provide a lightweight and easy to use alternative to soap4r. If you're starting to use Savon, please make sure to read this guide and make yourself familiar with [SOAP](http://www.w3.org/TR/soap/) itself, [WSDL documents](http://www.w3.org/TR/wsdl) and tools like [soapUI](http://www.eviware.com).

Table of contents
-----------------

* [Installation](#installation)
* [Runtime dependencies](#runtime_dependencies)
* [Getting started](#getting_started)
* [The WSDL object](#the_wsdl_object)
* [The HTTP object](#the_http_object)
* [The WSSE object](#the_wsse_object)
* [Executing SOAP requests](#executing_soap_requests)
* [The SOAP object](#the_soap_object)
* [The Response object](#the_response_object)
* [Error handling](#error_handling)
* [Global configuration](#global_configuration)
* [Alternative libraries](#alternative_libraries)

Installation
------------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

{% highlight bash %}
$ gem install savon
{% endhighlight %}

Runtime dependencies
--------------------

* [Builder](http://rubygems.org/gems/builder) ~> 2.1.2
* [Crack](http://rubygems.org/gems/crack) ~> 0.1.8
* [HTTPI](http://rubygems.org/gems/httpi) >= 0.4.0

HTTPI is an interface supporting multiple HTTP libraries. It defaults to use [HTTPClient](http://rubygems.org/gems/httpclient). Make sure to set up your $LOADPATH to include the HTTP library of your choice.

Getting started
---------------

Savon is based around the [Savon::Client](http://github.com/rubiii/savon/blob/dev/lib/savon/client.rb) object. It represents a particular SOAP service and lets you set up and execute SOAP requests. So lets create a client using a remote WSDL document:

{% highlight ruby %}
client = Savon::Client.new do
  wsdl.document = "http://service.example.com?wsdl"
end
{% endhighlight %}

`Savon::Client.new` method accepts a block to be evaluated in the context of the client object. So you can use method calls inside the block, but local variables won't work. For more information on this, I recommend you read about [instance_eval with delegation](http://www.dcmanges.com/blog/ruby-dsls-instance-eval-with-delegation).

If you don't like this or if it's actually a problem for you, you can use block arguments to specify which objects you would like to receive and Savon will yield those instead of instance evaluating the block. The `.new` method accepts 1-3 arguments and yields these objects:

    [wsdl, http, wsse]

For example, to work with the wsdl and http object, you could specify only two of the three possible arguments:

{% highlight ruby %}
client = Savon::Client.new do |wsdl, http|
  wsdl.document = "http://service.example.com?wsdl"
  http.proxy = "http://proxy.example.com"
end
{% endhighlight %}

The objects mentioned above can also be used after instantiating the client (outside of the block) and the following sections provide details about what they can be used for.

The WSDL object
---------------

The WSDL object is actually called [Savon::WSDL::Document](http://github.com/rubiii/savon/blob/dev/lib/savon/wsdl/document.rb), but I'll refer to all objects via shortnames. You can think of the wsdl as a representation of a WSDL document.

### Inspecting a Service

Specifying the location of a WSDL document gives you access to a couple of methods for inspecting your service.

{% highlight ruby %}
# specifies a remote location
wsdl.document = "http://service.example.com?wsdl"

# uses a local document
wsdl.document = "../wsdl/authentication.xml"
{% endhighlight %}

The following examples assume you specified a WSDL location.

{% highlight ruby %}
# returns the target namespace
wsdl.namespace  # => "http://v1.example.com"

# returns the SOAP endpoint
wsdl.endpoint  # => "http://service.example.com"

# returns an Array of available SOAP actions
wsdl.soap_actions  # => [:create_user, :get_user, :get_all_users]

# returns the WSDL document as a String
wsdl.to_xml  # => "<wsdl:definitions name=\"AuthenticationService\" ..."
{% endhighlight %}

Note: your service will probably use (lower)CamelCase method names, but Savon maps those to snake_case Symbols for you.

### Working without a WSDL

Retrieving and parsing WSDL documents is a quite expensive operation. And even though Savon only does this once for every client, my recommendation is to not use a WSDL (at least in production) and directly access the SOAP endpoint instead. This requires you to specify the SOAP endpoint and target namespace instead of a WSDL location.

{% highlight ruby %}
client = Savon::Client.new do
  wsdl.endpoint = "http://service.example.com"
  wsdl.namespace = "http://v1.example.com"
end
{% endhighlight %}

Whether you're using a WSDL or specifying the target namespaces manually, Savon will register the `xmlns:wsdl` namespace (pointing to the target namespace) for you.

The HTTP object
---------------

[HTTPI::Request](http://github.com/rubiii/httpi/blob/master/lib/httpi/request.rb) is provided by the [HTTPI](http://rubygems.org/gems/httpi) gem and provides various settings for customizing HTTP requests. Savon executes GET requests for retrieving remote WSDL documents and POST requests for each SOAP request.

So because it's a dependency, I'm only going to document one SOAP-specific detail and point you to the [HTTPI documentation](http://github.com/rubiii/httpi) for additional information.

Note: HTTPI is still a very young project and might not support everything you need. Please don't hesitate to [file bugs](http://github.com/rubiii/httpi/issues) or [make wishes](http://httpi.uservoice.com) for the library to support additional features.

### SOAPAction

...

The WSSE object
---------------

[Savon::WSSE](http://github.com/rubiii/savon/blob/dev/lib/savon/wsse.rb) allows you to use [WSSE authentication](http://www.oasis-open.org/committees/wss/documents/WSS-Username-02-0223-merged.pdf) (PDF).

{% highlight ruby %}
# sets the WSSE credentials
wsse.credentials "username", "password"

# enables WSSE digest authentication
wsse.credentials "username", "password", :digest
{% endhighlight %}

Executing SOAP requests
-----------------------

Now for the fun part. To execute SOAP request, you will now learn about the `Savon::Client#request` method. Lets look at a very basic example for executing a SOAP request to a `get_all_users` action.

{% highlight ruby %}
response = client.request :get_all_users
{% endhighlight %}

This single argument (the name of the SOAP action to call) works in different ways depending on whether you use a WSDL document. If you do, Savon will parse the WSDL for SOAP actions and convert their names to snake_case Symbols for you. When you're [not using a WSDL](working_without_a_wsdl), the argument will (by convention) be converted to lowerCamelCase.

{% highlight ruby %}
:get_all_users.to_s.lower_camelcase  # => "getAllUsers"
:get_pdf.to_s.lower_camelcase        # => "getPdf"
{% endhighlight %}

This convention might not work for you if your service requires CamelCase method names or contains methods with UPPERCASE acronyms. But don't worry. If you pass in a String instead of a Symbol, Savon will not convert the argument.

{% highlight ruby %}
response = client.request "GetPDF"
{% endhighlight %}

The argument(s) passed to the `#request` method will affect the SOAP input tag inside the XML request. To make sure you know what this means, here's an example of a simple request:

{% highlight xml %}
<env:Envelope xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">
  <env:Body>
    <getAllUsers />  <!-- the SOAP input tag -->
  </env:Body>
</env:Envelope>
{% endhighlight %}

Now you know what happens when you pass a single argument. But fairly often you need to prefix the input tag with the target namespace of your service like this:

{% highlight xml %}
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsdl="http://v1.example.com">
  <env:Body>
    <wsdl:getAllUsers />
  </env:Body>
</env:Envelope>
{% endhighlight %}

So if you pass two arguments to the `#request` method, the first (a Symbol) will be used for the namespace and the second (a Symbol or String) will be the SOAP action to call:

{% highlight ruby %}
response = client.request :wsdl, :get_all_users
{% endhighlight %}

On rare occasions, you may actually need to attach XML attributes to the input tag. In that case, you can pass a Hash of attributes to the name of your SOAP action and the optional namespace:

{% highlight ruby %}
response = client.request :wsdl, "GetPDF", :id => 1
{% endhighlight %}

These three arguments will generate the following input tag:

{% highlight xml %}
<wsdl:GetPDF id="1" />
{% endhighlight %}

Since most SOAP actions require you to pass arguments for e.g. the user to return, you need additional settings. Luckily you're already familiar with [passing a block to a method](#getting_started), right? `Savon::Client#request` also accepts a block for you to access these object:

    [soap, wsdl, http, wsse]

Notice, that the list is almost the same as the one for `Savon::Client.new`. Except now, there is an additional object called soap. In contrast to the other three objects which you should already know, a new soap object is created for every request.

The SOAP object
---------------

[Savon::SOAP::XML](http://github.com/rubiii/savon/blob/dev/lib/savon/soap/xml.rb) is tied to a single SOAP request and lets you set up the XML to send.

### SOAP version

Savon by default expects your services to be based on SOAP 1.1. For SOAP 1.2 services, you can set the SOAP version per request:

{% highlight ruby %}
response = client.request :get_user do
  soap.version = 2
end
{% endhighlight %}

Changing the SOAP version affects the `xmlns:soap` namespace and [error handling](#error_handling).

### Namespaces

...

### SOAP body

In most cases you need to at least specify the arguments required by the SOAP action you're going to call. If, for example, you call a `get_user` action and it expects the ID of the user to return, you can simply use a Hash:

{% highlight ruby %}
response = client.request :get_user do
  soap.body = { :id => 1 }
end
{% endhighlight %}

As you already saw before, Savon is based on a few conventions to make the experience of having to work with SOAP and XML as pleasant as possible. The Hash passed to `Savon::SOAP::XML#body=` is not an exception. It is translated to XML using the `Hash#to_soap_xml` method provided by Savon.

Here's a more complex example:

{% highlight ruby %}
response = client.request :wsdl, "CreateUser" do
  soap.body = {
    :first_name => "The",
    :last_name  => "Hoff",
    "TV"        => ["Knight Rider", "Baywatch"]
  }
end
{% endhighlight %}

As with the SOAP action, Symbol keys will be converted to lowerCamelCase and String keys won't be touched. The previous examples generates the following XML:

{% highlight xml %}
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsdl="http://v1.example.com">
  <env:Body>
    <wsdl:GetUser>
      <firstName>The</firstName>
      <lastName>Hoff</lastName>
      <TV>Knight Rider</TV>
      <TV>Baywatch</TV>
    </wsdl:GetUser>
  </env:Body>
</env:Envelope>
{% endhighlight %}

Some services actually require the XML elements to be in a specific order. If you don't use Ruby 1.9 (and you should), you can not be sure about the order of Hash elements and have to specify it using an Array under a special `:order!` key:

{% highlight ruby %}
{ :last_name => "Hoff", :first_name => "The", :order! => [:first_name, :last_name] }
{% endhighlight %}

This will make sure, that the lastName tag follows the firstName.

Assigning arguments to XML tags using a Hash is even more difficult. It requires another Hash under an `attributes!` key containing a key matching the XML tag and the Hash of attributes to add:

{% highlight ruby %}
{ :first_name => "TheHoff", :last_name => nil, :attributes! => { :last_name => { "xsi:nil" => true } } }
{% endhighlight %}

This example will be translated to the following XML:

{% highlight xml %}
<firstName>TheHoff</firstName><lastName xsi:nil="true"></lastName>
{% endhighlight %}

I would not recommend using a Hash for the SOAP body if you need to create a complex XML structure, because there are better alternatives. One of them is to pass a block to the `Savon::SOAP::XML#body` method. Savon will then yield a `Builder::XmlMarkup` instance for you to use.

{% highlight ruby %}
soap.body do |xml|
  xml.firstName("The")
  xml.lastName("Hoff")
end
{% endhighlight %}

Last but not least, you can also create and use a simple String (created with Builder or any another tool):

{% highlight ruby %}
soap.body = "<firstName>The</firstName><lastName>Hoff</lastName>"
{% endhighlight %}

### SOAP header

...

### Custom XML

...

The Response object
-------------------

...

Error handling
--------------

...

Global configuration
--------------------

...

Alternative libraries
---------------------

...
