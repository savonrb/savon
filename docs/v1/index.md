Version 1
---------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

{% highlight bash %}
$ gem install savon
{% endhighlight %}

The project is [hosted on GitHub](http://github.com/savonrb/savon), it has [source code documentation](http://rubydoc.info/gems/savon/frames), it uses [continuous integration](http://travis-ci.org/#!/savonrb/savon), support can be found in the [mailing list](https://groups.google.com/forum/#!forum/savonrb) and thanks to Ryan Bates, there's even a [Railscast](http://railscasts.com/episodes/290-soap-with-savon).


Getting started
---------------

[`Savon::Client`](http://github.com/savonrb/savon/blob/master/lib/savon/client.rb) is the
interface to your SOAP service. The easiest way to get started is to use a local or remote
WSDL document.

{% highlight ruby %}
client = Savon.client("http://service.example.com?wsdl")
{% endhighlight %}

`Savon.client` accepts a block inside which you can access local variables and even public
methods from your own class, but instance variables won't work. If you want to know why that is,
I'd recommend reading about
[instance_eval with delegation](http://www.dcmanges.com/blog/ruby-dsls-instance-eval-with-delegation).

If you don't like this behaviour or if it's creating a problem for you, you can accept arguments
in your block to specify which objects you would like to receive and Savon will yield those instead
of instance evaluating the block. The block accepts 1-3 arguments and yields the following objects.

    [wsdl, http, wsse]

These objects provide methods for setting up the client. In order to use the wsdl and http object,
you can specify two (of the three possible) arguments.

{% highlight ruby %}
Savon.client do |wsdl, http|
  wsdl.document = "http://service.example.com?wsdl"
  http.proxy = "http://proxy.example.com"
end
{% endhighlight %}

You can also access them through methods of your client instance.

{% highlight ruby %}
client.wsse.credentials "username", "password"
{% endhighlight %}

### (Not) using a WSDL

You can instantiate a client with or without a (local or remote) WSDL document. Using a WSDL
is a little easier because Savon can parse the document for the target namespace, endpoint,
available SOAP actions etc. But the (remote) WSDL has to be downloaded and parsed once for every
client which comes with a performance penalty.

To use a local WSDL, you specify the path to the file instead of the remote location:

{% highlight ruby %}
Savon.client File.expand_path("../wsdl/ebay.xml", __FILE__)
{% endhighlight %}

With the client set up, you can now see what Savon knows about your service through methods offered
by [`Savon::WSDL::Document`](http://github.com/savonrb/savon/blob/master/lib/savon/wsdl/document.rb) (wsdl).
It's not too much, but it can save you some code.

{% highlight ruby %}
# the target namespace
client.wsdl.namespace     # => "http://v1.example.com"

# the SOAP endpoint
client.wsdl.endpoint      # => "http://service.example.com"

# available SOAP actions
client.wsdl.soap_actions  # => [:create_user, :get_user, :get_all_users]

# the raw document
client.wsdl.to_xml        # => "<wsdl:definitions ..."
{% endhighlight %}

Your service probably uses (lower)CamelCase names for actions and params, but Savon maps those to
snake_case Symbols for you.

To use Savon without a WSDL, you initialize a client and set the SOAP endpoint and target namespace.

{% highlight ruby %}
Savon.client do
  wsdl.endpoint = "http://service.example.com"
  wsdl.namespace = "http://v1.example.com"
end
{% endhighlight %}

### Qualified Locals

Savon reads the value for [elementFormDefault](http://www.w3.org/TR/xmlschema-0/#QualLocals) from a
given WSDL and defaults to `:unqualified` in case no WSDL document is used. The value specifies whether
all locally declared elements in a schema must be qualified. As of v0.9.9, the value can be manually
set to `:unqualified` or `:qualified` when setting up the client.

{% highlight ruby %}
Savon.client do
  wsdl.element_form_default = :unqualified
end
{% endhighlight %}

### Preparing for HTTP

Savon uses [HTTPI](http://rubygems.org/gems/httpi) to execute GET requests for WSDL documents and
POST requests for SOAP requests. HTTPI is an interface to HTTP libraries like Curl and Net::HTTP.

The library comes with a request object called
[`HTTPI::Request`](http://github.com/savonrb/httpi/blob/master/lib/httpi/request.rb) (http)
which can accessed through the client. I'm only going to document a few details about it and
then hand over to the official documentation.

SOAPAction is an HTTP header information required by legacy services. If present, the header
value must have double quotes surrounding the URI-reference (SOAP 1.1. spec, section 6.1.1).
Here's how you would set/overwrite the SOAPAction header in case you need to:

{% highlight ruby %}
client.http.headers["SOAPAction"] = '"urn:example#service"'
{% endhighlight %}

If your service relies on cookies to handle sessions, you can grab the cookie from the
[`HTTPI::Response`](http://github.com/savonrb/httpi/blob/master/lib/httpi/response.rb) and set
it for subsequent requests.

{% highlight ruby %}
client.http.headers["Cookie"] = response.http.headers["Set-Cookie"]
{% endhighlight %}

### WSSE authentication

Savon comes with [`Savon::WSSE`](http://github.com/savonrb/savon/blob/master/lib/savon/wsse.rb) (wsse)
for you to use wsse:UsernameToken authentication.

{% highlight ruby %}
client.wsse.credentials "username", "password"
{% endhighlight %}

Or wsse:UsernameToken digest authentication.

{% highlight ruby %}
client.wsse.credentials "username", "password", :digest
{% endhighlight %}

Or wsse:Timestamp authentication.

{% highlight ruby %}
client.wsse.timestamp = true
{% endhighlight %}

By setting `#timestamp` to `true`, the wsu:Created is set to `Time.now` and wsu:Expires is set to
`Time.now + 60`. You can also specify your own values manually.

{% highlight ruby %}
client.wsse.created_at = Time.now
client.wsse.expires_at = Time.now + 60
{% endhighlight %}

`Savon::WSSE` is based on an
[autovivificating Hash](http://stackoverflow.com/questions/1503671/ruby-hash-autovivification-facets).
So if you need to add custom tags, you can add them.

{% highlight ruby %}
client.wsse["wsse:Security"]["wsse:UsernameToken"] =
  { "Organization" => "ACME" }
{% endhighlight %}

When generating the XML for the request, this Hash will be merged with another Hash containing all the
default tags and values. This way you might digg into some code, but then you can even overwrite the
default values.


Executing SOAP requests
-----------------------

Now for the fun part. To execute SOAP requests, you use the `Savon::Client#request` method. Here's a
very basic example of executing a SOAP request to a `get_all_users` action.

{% highlight ruby %}
response = client.request :get_all_users
{% endhighlight %}

This single argument (the name of the SOAP action to call) works in different ways depending on whether
you're using a WSDL document. If you do, Savon will parse the WSDL document for available SOAP actions
and convert their names to snake_case Symbols for you.

Savon converts snake_case_symbols to lowerCamelCase like this:

{% highlight ruby %}
:get_all_users.to_s.lower_camelcase  # => "getAllUsers"
:get_pdf.to_s.lower_camelcase        # => "getPdf"
{% endhighlight %}

This convention might not work for you if your service requires CamelCase method names or methods with
UPPERCASE acronyms. But don't worry. If you pass in a String instead of a Symbol, Savon will not convert
the argument. The difference between Symbols and String identifiers is one of Savon's convention.

{% highlight ruby %}
response = client.request "GetPDF"
{% endhighlight %}

The argument(s) passed to the `#request` method will affect the SOAP input tag inside the SOAP request.  
To make sure you know what this means, here's an example for a simple request:

{% highlight xml %}
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <env:Body>
    <getAllUsers />  <!-- the SOAP input tag -->
  </env:Body>
</env:Envelope>
{% endhighlight %}

Now if you need the input tag to be namespaced `<wsdl:getAllUsers />`, you pass two arguments
to the `#request` method. The first (a Symbol) will be used for the namespace and the second
(a Symbol or String) will be the SOAP action to call:

{% highlight ruby %}
response = client.request :wsdl, :get_all_users
{% endhighlight %}

You may also need to bind XML attributes to the input tag. In this case, you pass a Hash of
attributes following to the name of your SOAP action and the optional namespace.

{% highlight ruby %}
response = client.request :wsdl, "GetPDF", id: 1
{% endhighlight %}

These arguments result in the following input tag.

{% highlight xml %}
<wsdl:GetPDF id="1" />
{% endhighlight %}

### Wrestling with SOAP

To interact with your service, you probably need to specify some SOAP-specific options.
The `#request` method is the second important method to accept a block and lets you access the
following objects.

    [soap, wsdl, http, wsse]

Notice, that the list is almost the same as the one for `Savon.client`. Except now, there is an
additional object called soap. In contrast to the other three objects, the soap object is tied to single
requests.

[`Savon::SOAP::XML`](http://github.com/savonrb/savon/blob/master/lib/savon/soap/xml.rb) (soap) can only be
accessed inside this block and Savon creates a new soap object for every request.

Savon by default expects your services to be based on SOAP 1.1. For SOAP 1.2 services, you can set the
SOAP version per request.

{% highlight ruby %}
response = client.request :get_user do
  soap.version = 2
end
{% endhighlight %}

If you don't pass a namespace to the `#request` method, Savon will attach the target namespaces to
`"xmlns:wsdl"`. If you pass a namespace, Savon will use it instead of the default.

{% highlight ruby %}
client.request :v1, :get_user
{% endhighlight %}

{% highlight xml %}
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xmlns:v1="http://v1.example.com">
  <env:Body>
    <v1:GetUser>
  </env:Body>
</env:Envelope>
{% endhighlight %}

You can always set namespaces and overwrite namespaces. They're stored as a Hash.

{% highlight ruby %}
# setting a namespace
soap.namespaces["xmlns:g2"] = "http://g2.example.com"

# overwriting "xmlns:wsdl"
soap.namespaces["xmlns:wsdl"] = "http://ns.example.com"
{% endhighlight %}

### A little interaction

To call the `get_user` action of a service and pass the ID of the user to return, you can use
a Hash for the SOAP body.

{% highlight ruby %}
response = client.request :get_user do
  soap.body = { id: 1 }
end
{% endhighlight %}

If you only need to send a single value or if you like to create a more advanced object to build
the SOAP body, you can pass any object that's not a Hash and responds to `to_s`.

{% highlight ruby %}
response = client.request :get_user_by_id do
  soap.body = 1
end
{% endhighlight %}

As you already saw before, Savon is based on a few conventions to make the experience of having to
work with SOAP and XML as pleasant as possible. The Hash is translated to XML using
[Gyoku](http://rubygems.org/gems/gyoku) which is based on the same conventions.

{% highlight ruby %}
soap.body = {
  :first_name => "The",
  :last_name  => "Hoff",
  "FAME"      => ["Knight Rider", "Baywatch"]
}
{% endhighlight %}

As with the SOAP action, Symbol keys will be converted to lowerCamelCase and String keys won't be
touched. The previous example generates the following XML.

{% highlight xml %}
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsdl="http://v1.example.com">
  <env:Body>
    <wsdl:CreateUser>
      <firstName>The</firstName>
      <lastName>Hoff</lastName>
      <FAME>Knight Rider</FAME>
      <FAME>Baywatch</FAME>
    </wsdl:CreateUser>
  </env:Body>
</env:Envelope>
{% endhighlight %}

Some services actually require the XML elements to be in a specific order. If you don't use Ruby 1.9
(and you should), you can not be sure about the order of Hash elements and have to specify the correct
order using an Array under a special `:order!` key.

{% highlight ruby %}
{
  :last_name  => "Hoff",
  :first_name => "The",
  :order!     => [:first_name, :last_name]
}
{% endhighlight %}

This will make sure, that the lastName tag follows the firstName.

Assigning arguments to XML tags using a Hash is even more difficult. It requires another Hash under
an `:attributes!` key containing a key matching the XML tag and the Hash of attributes to add.

{% highlight ruby %}
{
  :city        => nil,
  :attributes! => { :city => { "xsi:nil" => true } }
}
{% endhighlight %}

This example will be translated to the following XML.

{% highlight xml %}
<city xsi:nil="true"></city>
{% endhighlight %}

I would not recommend using a Hash for the SOAP body if you need to create complex XML structures,
because there are better alternatives. One of them is to pass a block to the `Savon::SOAP::XML#body`
method. Savon will then yield a `Builder::XmlMarkup` instance for you to use.

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

Besides the body element, SOAP requests can also contain a header with additional information.
Savon sees this header as just another Hash following the same conventions as the SOAP body Hash.

{% highlight ruby %}
soap.header = { "SecretKey" => "secret" }
{% endhighlight %}

If you're sure that none of these options work for you, you can completely customize the XML to be used
for the SOAP request.

{% highlight ruby %}
soap.xml = "<custom><soap>request</soap></custom>"
{% endhighlight %}

The `Savon::SOAP::XML#xml` method also accepts a block and yields a `Builder::XmlMarkup` instance.

{% highlight ruby %}
namespaces = {
  "xmlns:soapenv" => "http://schemas.xmlsoap.org/soap/envelope/",
  "xmlns:blz" => "http://thomas-bayer.com/blz/"
}

soap.xml do |xml|
  xml.soapenv(:Envelope, namespaces) do |xml|
    xml.soapenv(:Body) do |xml|
      xml.blz(:getBank) do |xml|
        xml.blz(:blz, "24050110")
      end
    end
  end
end
{% endhighlight %}

Please take a look at the examples for some hands-on exercise.


Handling the response
---------------------

`Savon::Client#request` returns a
[`Savon::SOAP::Response`](http://github.com/savonrb/savon/blob/master/lib/savon/soap/response.rb).
Everything's really just a Hash.

{% highlight ruby %}
response.to_hash  # => { :response => { :success => true, :name => "John" } }
{% endhighlight %}

Alright, sometimes it's XML.

{% highlight ruby %}
response.to_xml  # => "<response><success>true</success><name>John</name></response>"
{% endhighlight %}

The response also contains the [`HTTPI::Response`](http://github.com/savonrb/httpi/blob/master/lib/httpi/response.rb)
which (obviously) contains information about the HTTP response.

{% highlight ruby %}
response.http  # => #<HTTPI::Response:0x1017b4268 ...
{% endhighlight %}

### In case of an emergency

By default, Savon raises both `Savon::SOAP::Fault` and `Savon::HTTP::Error` when encountering these
kind of errors.

{% highlight ruby %}
begin
  client.request :get_all_users
rescue Savon::SOAP::Fault => fault
  log fault.to_s
end
{% endhighlight %}

Both errors inherit from `Savon::Error`, so you can catch both very easily.

{% highlight ruby %}
begin
  client.request :get_all_users
rescue Savon::Error => error
  log error.to_s
end
{% endhighlight %}

You can change the default of raising errors and if you did, you can still ask the response to check
whether the request was successful.

{% highlight ruby %}
response.success?     # => false
response.soap_fault?  # => true
response.http_error?  # => false
{% endhighlight %}

And you can access the error objects themselves.

{% highlight ruby %}
response.soap_fault  # => Savon::SOAP::Fault
response.http_error  # => Savon::HTTP::Error
{% endhighlight %}

Please notice, that these methods always return an error object, even if no error exists. To check if
an error occured, you can either ask the response or the error objects.

{% highlight ruby %}
response.soap_fault.present?  # => true
response.http_error.present?  # => false
{% endhighlight %}


Creating Model objects
----------------------

Since v0.9.8, Savon ships with a very lightweight DSL that can be used inside or along your
domain models. You can think of it as a service mapped to a Class interface. All you need to
do is extend `Savon::Model` and your Class can act as a SOAP client.

You can either specify the location of a WSDL document:

{% highlight ruby %}
class User
  extend Savon::Model

  document "http://service.example.com?wsdl"
end
{% endhighlight %}

or manually set the SOAP endpoint and target namespace and not use a WSDL:

{% highlight ruby %}
class User
  extend Savon::Model

  endpoint "http://service.example.com"
  namespace "http://v1.service.example.com"
end
{% endhighlight %}

You can also set some default HTTP headers and HTTP basic and WSSE auth credentials:

{% highlight ruby %}
class User
  extend Savon::Model

  headers { "AuthToken" => "BdB)33*Rdr" }

  basic_auth "username", "password"
  wsse_auth "username", "password", :digest
end
{% endhighlight %}

To really benefit from Savon's conventions and knowledge of your service, you should tell Savon about
the service methods you would like to expose through your Model. `Savon::Model` creates both class and
instance methods for every action. These methods accept a SOAP body Hash and return a
`Savon::SOAP::Response`. You can wrap them or just call them directly:

{% highlight ruby %}
class User
  extend Savon::Model

  actions :get_user, :get_all_users

  def self.all
    get_all_users.to_array
  end

end
{% endhighlight %}

You can even overwrite them and delegate to `super` to call the original method:

{% highlight ruby %}
class User
  extend Savon::Model

  actions :get_user, :get_all_users

  def get_user(id)
    super(user_id: id).body[:get_user_response][:return]
  end

end
{% endhighlight %}

The `Savon::Client` instance used by your Model lives at `.client` inside your class. It gets initialized
lazily whenever you call any other class or instance method that tries to access the client. In case you
need to control how the client gets initialized, you can pass a block to `.client` before it's memoized:

{% highlight ruby %}
class User
  extend Savon::Model

  client do
    http.headers["Pragma"] = "no-cache"
  end

end
{% endhighlight %}

Last but not least, you can opt-out of defining any service methods and directly use the `Savon::Client` instance:

{% highlight ruby %}
class User
  extend Savon::Model

  document "http://service.example.com?wsdl"

  def find_by_id(id)
    response = client.request(:find_user) do
      soap.body = { id: id }
    end

    response.body[:find_user_response][:return]
  end

end
{% endhighlight %}

In case you previously used the [savon_model](http://rubygems.org/gems/savon_model) gem, please make sure to
remove it from your project as it may conflict with the new implementation.


Configuration
-------------

Savon provides a couple of basic configuration options:

{% highlight ruby %}
Savon.configure do |config|

  # By default, Savon logs each SOAP request and response to $stdout.
  # Here's how you can disable logging:
  config.log = false

  # The default log level used by Savon is :debug.
  config.log_level = :info

  # In a Rails application you might want Savon to use the Rails logger.
  config.logger = Rails.logger

  # The XML logged by Savon can be formatted for debugging purposes.
  # Unfortunately, this feature comes with a performance and is not
  # recommended for production environments.
  config.pretty_print_xml = true

  # Savon raises SOAP and HTTP errors, but you can disabling this behavior.
  config.raise_errors = false

  # Savon expects your service to use SOAP 1.1. You can change that to 1.2
  # which affects error handling and smaller differences. If you have to
  # set this, it's probably a bug. Please open a ticket.
  config.soap_version = 2

  # The XML namespace identifier used for the SOAP envelope defaults to :env
  # but can be configured to use a different identifier. If you need this
  # feature, please open a ticket because Savon should figure out the
  # namespace and identifier itself.
  config.env_namespace = :soapenv

  # The SOAP header can be configured to default to a Hash that gets
  # translated to XML by Gyoku. I would love to remove this feature,
  # so if you rely on it, open a ticket and let me know why you need it.
  config.soap_header = { auth: { username: "admin", password: "secret" } }

end
{% endhighlight %}

The example above used the global config. Each `Savon::Client` clones the global config
on instantiation to allow different client objects to use a different logger, custom
error handling or any other setting.

Here's an example of how to access the per-client config and change the error handling:

{% highlight ruby %}
client = Savon.client("http://service.example.com?wsdl")
client.config.raise_errors = false
{% endhighlight %}

Please note that disabling Savon's logger does not disable logging of any dependant libraries.  
[HTTPI](http://rubygems.org/gems/httpi) for example will continue to log HTTP requests and has
to be configured separately. Here's how you can disable logging for HTTPI:

{% highlight ruby %}
HTTPI.log = false
{% endhighlight %}


Code hooks
----------

Savon has a concept of hooks, which kind of work like filters which you might know from tools like
Rails or RSpec. Currently there's only one hook to use, but it's a pretty powerful one.

The hook is called `soap_request` and acts like an around filter wrapping the POST request executed
to call a SOAP service. It yields a callback object that can be called to execute the actual POST request.
It also yields the current `Savon::SOAP::Request` for you to collect information about the request.

This can be used to measure the time of the actual request:

{% highlight ruby %}
Savon.configure do |config|
  config.hooks.define(:measure, :soap_request) do |callback, request|
    Timer.log(:start, Time.now)
    response = callback.call
    Timer.log(:end, Time.now)
    response
  end
end
{% endhighlight %}

or to replace the SOAP call and return a pre-defined response:

{% highlight ruby %}
Savon.configure do |config|
  config.hooks.define(:mock, :soap_request) do |callback, request|
    HTTPI::Response.new(200, {}, "")
  end
end
{% endhighlight %}

This is actually how the [savon_spec](https://rubygems.org/gems/savon_spec) gem is able to mock
SOAP calls, add expectations on the request and return fixtures and pre-defined responses.

The first argument to `Savon::Hooks::Group#define` is a unique name to identify single hooks.
This can be used to remove previously defined hooks:

{% highlight ruby %}
Savon.configure do |config|
  config.hooks.reject(:measure, :mock)
end
{% endhighlight %}


Troubleshooting
---------------

**When Savon can't read the available actions from a WSDL**

{% highlight ruby %}
client.wsdl.soap_actions  # => []
{% endhighlight %}

Check if the WSDL uses imports to separate parts of the service description into multiple files.
If that's the case, then [Savon's WSDL parser](https://github.com/savonrb/wasabi) might not be able
to work as expected. This is a known and rather complicated issue on top of my todo list.


Additional resources
--------------------

**Are you stuck?**

Then you're probably looking for someone to help. The [Mailing list](https://groups.google.com/forum/#!forum/savonrb)
is a good place to search for useful information and ask questions. Please make sure to post your
questions to the Mailing list instead of sending private messages so others can benefit from these
information.

**Did you run into a problem?**

So you think something's not working like it's supposed to? Or do you need a feature that Savon
doesn't support? Take a look at the [open issues](https://github.com/savonrb/savon/issues)
over own Github to see if this has already been reported. If it has not been reported yet,
please open an issue and make sure to leave useful information to debug the problem.

**Anything missing in this guide?**

Please [fork this guide](https://github.com/savonrb/savonrb.com) on Github and help to improve it!

**Do you want to help out?**

* Answer questions on the [Mailing list](https://groups.google.com/forum/#!forum/savonrb) or
  [Stack Overflow](http://stackoverflow.com/search?q=ruby+soap)
* Improve the documentation by writing an article or tutorial
* You could also help out with [open issues](https://github.com/savonrb/savon/issues)
* Or [test patches](https://github.com/savonrb/savon/pulls) and provide your feedback

**Are you looking for updates?**

If you're on Twitter, make sure to follow [@savonrb](http://twitter.com/savonrb) for updates
on bug fixes, new features and releases.


Alternatives
------------

If you feel like there's no way Savon will fit your needs, you should take a look at  
[The Ruby Toolbox](http://ruby-toolbox.com/categories/soap.html) to find an alternative.

