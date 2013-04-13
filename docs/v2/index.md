Version 2
---------

Savon is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

{% highlight bash %}
$ gem install savon
{% endhighlight %}

The project is [hosted on GitHub](http://github.com/savonrb/savon), it has [source code documentation](http://rubydoc.info/gems/savon/frames), it uses [continuous integration](http://travis-ci.org/#!/savonrb/savon) and support can be found in the [mailing list](https://groups.google.com/forum/#!forum/savonrb).


Client
------

The new client is supposed be a lot simpler to use, because everything in Savon 2.0 is based on a defined set
of global and local options. To create a new client based on a WSDL document, you could set the global `:wsdl`
option by passing a Hash to the `Savon.client` "factory method". The client's constructor accepts various
[global options](#globals) which are specific to a service.

``` ruby
client = Savon.client(wsdl: "http://example.com?wsdl")
```

Along with the simple Hash-based interface, Savon also comes with an interface based on blocks. This should look
familiar to you if you used Savon 1.x before. If you're passing a block to the constructor, it is executed using the
[instance_eval with delegation](http://www.dcmanges.com/blog/ruby-dsls-instance-eval-with-delegation) pattern.
It's a smart, but ugly, but convenient little hack.

``` ruby
client = Savon.client do
  wsdl "http://example.com?wsdl"
end
```

The downside to this interface is, that it doesn't allow you to use instance variables inside the block.
You can only use local variables or call methods on your class. If you don't mind typing a few more
characters, you could accept an argument in your block and Savon will simply yield the global options
to it. That way, you can use as many instance variables as you like.

``` ruby
client = Savon.client do |globals|
  globals.wsdl @wsdl
end
```

In case your service doesn't have a WSDL, you might need to provide Savon with various other options.
For example, Savon needs to know about the SOAP endpoint and target namespace of your service.

``` ruby
client = Savon.client do
  endpoint "http://example.com"
  namespace "http://v1.example.com"
end
```

A nice little feature that comes with a WSDL, is that Savon can tell you about the available operations.

``` ruby
client.operations  # => [:authenticate, :find_user]
```

But the client really exists to send SOAP messages, so let's do that.

``` ruby
response = client.call(:authenticate, message: { username: "luke", password: "secret" })
```

If you used Savon before, this should also look familiar to you. But in contrast to the old client,
the new `#call` method does not provide the same interface as the old `#request` method. It's all about
options, so here's where you have various [local options](#locals) that are specific to a request.

The `#call` method supports the same interface as the constructor. You can pass a simple Hash or
a block to use the instance_eval with delegation pattern.

``` ruby
response = client.call(:authenticate) do
  message username: "luke", password: "secret"
  convert_request_keys_to :camelcase
end
```

You can also accept an argument in your block and Savon will yield the local options to it.

``` ruby
response = client.call(:authenticate) do |locals|
  locals.message username: "luke", password: "secret"
  locals.wsse_auth "luke", "secret", :digest
end
```


Globals
-------

Global options are passed to the client's constructor and are specific to a service.

Although they are called "global options", they really are local to a client instance. Savon version 1 was
based on a global `Savon.configure` method to store the configuration. While this was a popular concept
back then, adapted by tons of libraries, its problem is global state. I tried to fix that problem.

#### wsdl

Savon accepts either a local or remote WSDL document which it uses to extract information like the SOAP
endpoint and target namespace of the service.

``` ruby
Savon.client(wsdl: "http://example.com?wsdl")
Savon.client(wsdl: "/Users/me/project/service.wsdl")
```

For learning how to read a WSDL document, read the [Beginner's Guide](http://predic8.com/wsdl-reading.htm) by Thomas Bayer.
It's a good idea to know what you're working with and this might really help you debug certain problems.

#### endpoint and namespace

In case your service doesn't offer a WSDL, you need to tell Savon about the SOAP endpoint and target
namespace of the service.

``` ruby
Savon.client(endpoint: "http://example.com", namespace: "http://v1.example.com")
```

The target namespace is used to namespace the SOAP message. In a WSDL, the target namespace is defined on the
`wsdl:definitions` (root) node, along with the service's name and namespace declarations.

``` xml
<wsdl:definitions
  name="AuthenticationWebServiceImplService"
  targetNamespace="http://v1_0.ws.auth.order.example.com/"
  xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/">
```

The SOAP endpoint is the URL at which your service accepts SOAP requests. It is usually defined at the bottom
of a WSDL, as the `location` attribute of a `soap:address` node.

``` xml
  <wsdl:service name="AuthenticationWebServiceImplService">
    <wsdl:port binding="tns:AuthenticationWebServiceImplServiceSoapBinding" name="AuthenticationWebServiceImplPort">
      <soap:address location="http://example.com/validation/1.0/AuthenticationService" />
    </wsdl:port>
  </wsdl:service>
</wsdl:definitions>
```

You can also use these options to overwrite these values in a WDSL document in case you need to.

#### raise_errors

By default, Savon raises SOAP fault and HTTP errors. You can disable both errors and query the response instead.

``` ruby
Savon.client(raise_errors: false)
```


### Globals: HTTP

#### proxy

You can specify a proxy server to use. This will be used for retrieving remote WSDL documents and actual SOAP requests.

``` ruby
Savon.client(proxy: "http://example.org")
```

#### headers

Additional HTTP headers for the request.

``` ruby
Savon.client(headers: { "Authentication" => "secret" })
```

#### timeouts

Both open and read timeout can be set (in seconds). This will be used for retrieving remote WSDL documents and actually
SOAP requests.

``` ruby
Savon.client(open_timeout: 5, read_timeout: 5)
```


### Globals: SSL

Unfortunately, SSL options were [missing from the initial 2.0 release](https://github.com/savonrb/savon/issues/344).
Please update to at least version 2.0.2 to use the following options. These will be used for retrieving remote WSDL
documents and actual SOAP requests.

#### ssl_verify_mode

You can disable SSL verification if you know what you're doing.

``` ruby
Savon.client(ssl_verify_mode: :none)
```

#### ssl_version

Change the SSL version to use.

``` ruby
Savon.client(ssl_version: :SSLv3)  # or one of [:TLSv1, :SSLv2]
```

#### ssl_cert_file

Sets the SSL cert file to use.

``` ruby
Savon.client(ssl_cert_file: "lib/client_cert.pem")
```

#### ssl_cert_key_file

Sets the SSL cert key file to use.

``` ruby
Savon.client(ssl_cert_key_file: "lib/client_key.pem")
```

#### ssl_ca_cert_file

Sets the SSL ca cert file to use.

``` ruby
Savon.client(ssl_ca_cert_file: "lib/ca_cert.pem")
```

#### ssl_cert_key_password

Sets the cert key password to decrypt an encrypted private key.

``` ruby
Savon.client(ssl_cert_key_password: "secret")
```


### Globals: Request

#### convert_request_keys_to

Savon tells [Gyoku](https://github.com/savonrb/gyoku) to convert SOAP message Hash key Symbols to lowerCamelcase tags.
You can change this to CamelCase, UPCASE or completely disable any conversion.

``` ruby
client = Savon.client do
  convert_request_keys_to :camelcase  # or one of [:lower_camelcase, :upcase, :none]
end

client.call(:find_user) do
  message(user_name: "luke")
end
```

This example converts all keys in the request Hash to CamelCase tags.

``` xml
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsdl="http://v1.example.com">
  <env:Body>
    <wsdl:FindUser>
      <UserName>luke</UserName>
    </wsdl:FindUser>
  </env:Body>
</env:Envelope>
```

#### soap_header

If you need to add custom XML to the SOAP header, you can use this option. This might be useful for setting a global
authentication token or any other kind of metadata.

``` ruby
Savon.client(soap_header: { "Token" => "secret" })
```

This is the header created for the options:

``` xml
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:v1="http://v1.example.com/">
  <env:Header>
    <Token>secret</Token>
  </env:Header>
</env:Envelope>
```

#### element_form_default

Savon should extract whether to qualify elements from the WSDL. If there is no WSDL, Savon defaults to `:unqualified`.

If you specified a WSDL but still need to use this option, please open an issue and make sure to
add your WSDL for debugging. Savon currently does not support WSDL imports, so in case your service
imports its type definitions from another file, the `element_form_default` value might be wrong.

``` ruby
Savon.client(element_form_default: :qualified)
```

#### env_namespace

Savon defaults to use `:env` as the namespace identifier for the SOAP envelope. If that doesn't work  for you, I would
like to know why. So please open an issue and make sure to add your WSDL for debugging.

``` ruby
Savon.client(env_namespace: :soapenv)
```

This is how the request's `envelope` looks like after changing the namespace identifier:

``` xml
<soapenv:Envelope
  xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/">
```

#### namespace_identifier

Should be extracted from the WSDL. If it doesn't have a WSDL, Savon falls back to `:wsdl`. No idea why anyone
would need to use this option.

``` ruby
Savon.client(namespace_identifier: :v1)
```

Notice the `v1:authenticate` message tag in the generated request:

``` xml
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:v1="http://v1.example.com/">
  <env:Body>
    <v1:authenticate></v1:authenticate>
  </env:Body>
</env:Envelope>
```

#### namespaces

You can add additional namespaces to the SOAP envelope tag.

``` ruby
namespaces = {
  "xmlns:v2" => "http://v2.example.com",
}

Savon.client(namespaces: namespaces)
```

This does what you would expect it to do. If you need to use this option, please open an issue and provide
your WSDL for debugging.

``` xml
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:v1="http://v1.example.com/"
    xmlns:v2="http://v2.example.com/">
  <env:Body>
    <v1:authenticate></v1:authenticate>
  </env:Body>
</env:Envelope>
```

#### encoding

Savon defaults to UTF-8.

``` ruby
Savon.client(encoding: "UTF-16")
```

Changing the default affects both the Content-Type header:

``` ruby
{ "Content-Type" => "text/xml;charset=UTF-16" }
```

and the XML instruction:

``` xml
<?xml version="1.0" encoding="UTF-16"?>
```

#### soap_version

Defaults to SOAP 1.1. Can be set to SOAP 1.2 to use a different SOAP endpoint.

``` ruby
Savon.client(soap_version: 2)
```


### Globals: Authentication

HTTP authentication will be used for retrieving remote WSDL documents and actual SOAP requests.

#### basic_auth

Savon supports HTTP basic authentication.

``` ruby
Savon.client(basic_auth: ["luke", "secret"])
```

#### digest_auth

And HTTP digest authentication. If you wish to use digest auth you must ensure that you have included the gem httpclient, or another one of the [HTTPI](https://github.com/savonrb/httpi) adapters that supports HTTP digest authentication.  Failing to do so will not produce errors, but if the HTTPI adapter ends up using net_http, digest authentication will not be performed.

``` ruby
Savon.client do
  digest_auth("lea", "top-secret")
end
```

#### wsse_auth

As well as WSSE basic/digest auth.

``` ruby
Savon.client(wsse_auth: ["lea", "top-secret"])

Savon.client do
  wsse_auth("lea", "top-secret", :digest)
end
```

#### wsse_timestamp

And activate WSSE timestamp auth.

``` ruby
Savon.client(wsse_timestamp: true)
```


### Globals: Response

#### strip_namespaces

Savon configures [Nori](https://github.com/savonrb/nori) to strip any namespace identifiers from the response.
If that causes problems for you, you can disable this behavior.

``` ruby
Savon.client(strip_namespaces: false)
```

Here's how the response Hash would look like if namespaces were not stripped from the response:

``` ruby
response.hash["soap:envelope"]["soap:body"]["ns2:authenticate_response"]
```

#### convert_response_tags_to

Savon tells [Nori](https://github.com/savonrb/nori) to convert any XML tag from the response to a snakecase Symbol.
This is why accessing the response as a Hash looks natural:

``` ruby
response.body[:user_response][:id]
```

You can specify your own `Proc` or any object that responds to `#call`. It is called for every XML
tag and simply has to return the converted tag.

``` ruby
upcase = lambda { |key| key.snakecase.upcase }
Savon.client(convert_response_tags_to: upcase)
```

You can have it your very own way.

``` ruby
response.body["USER_RESPONSE"]["ID"]
```


### Globals: Logging

#### logger

Savon logs to `$stdout` using Ruby's default Logger. Can be changed to any compatible logger.

``` ruby
Savon.client(logger: Rails.logger)
```

#### log_level

Can be used to limit the amount of log messages by increasing the severity.
Translates the Logger's integer values to Symbols for developer happiness.

``` ruby
Savon.client(log_level: :info)  # or one of [:debug, :warn, :error, :fatal]
```

#### log

Specifies whether Savon should log requests or not. Silences HTTPI is well.

``` ruby
Savon.client(log: false)
```

#### filters

Sensitive information should probably be removed from logs. If you don't have a central way of filtering your logs,
you can tell Savon about the message parameters to filter for you.

``` ruby
Savon.client(filters: [:password])
```

This filters the password in both the request and response.

``` xml
<env:Envelope
    xmlns:env='http://schemas.xmlsoap.org/soap/envelope/'
    xmlns:tns='http://v1_0.ws.auth.order.example.com/'>
  <env:Body>
    <tns:authenticate>
      <username>luke</username>
      <password>***FILTERED***</password>
    </tns:authenticate>
  </env:Body>
</env:Envelope>
```

#### pretty_print_xml

Pretty print the request and response XML in your logs for debugging purposes.

``` ruby
Savon.client(pretty_print_xml: true)
```


Requests
--------

To execute a SOAP request, you can ask Savon for an operation and call it with a message to send.

``` ruby
message = { username: 'luke', password: 'secret' }
response = client.call(:authenticate, message: message)
```

In this example, the Symbol `:authenticate` is the name of the SOAP operation and the `message` Hash is what
was known as the SOAP `body` Hash in version 1. The reason to change the naming is related to the SOAP request
and the fact that the former "body" never really influenced the entire SOAP body.

If Savon has a WSDL, it verifies whether your service actually contains the operation you're trying to call
and raises an `ArgumentError` in case it doesn't exist.

When you're calling a SOAP operation with a message Hash, Savon defaults to convert Hash key Symbols to
lowerCamelcase XML tags. It does not convert any Hash key Strings. You can change this with the global
`:convert_request_keys_to` option.

The operations `#call` method accepts a few local options.


Locals
------

Local options are passed to the client's `#call` method and are specific to a single request.

### Locals: HTTP

#### soap_action

You might need to set this if you don't have a WSDL. Otherwise, Savon should set the proper SOAPAction HTTP header for you.
If it doesn't, please open an issue and add the WSDL of your service.

``` ruby
client.call(:authenticate, soap_action: "urn:Authenticate")
```

#### cookies

Savon 2.0 tried to automatically handle cookies by storing the cookies from the last response and using them for
the next request. This is wrong and [it caused problems](https://github.com/savonrb/savon/issues/363). Savon 2.1
does not set the "Cookie" header for you, but it makes it easy for you to handle cookies yourself.

``` ruby
response     = client.call(:authenticate, message: credentials)
auth_cookies = response.http.cookies

client.call(:find_user, message: { id: 3 }, cookies: auth_cookies)
```

This option accepts an Array of `HTTPI::Cookie` objects or any object that responds to `cookies`
(like for example, an `HTTPI::Response`).


### Locals: Request

#### message

You probably want to add some arguments to your request. For simple XML which can easily be represented as a Hash,
you can pass the SOAP message as a Hash. Savon uses [Gyoku](https://github.com/savonrb/gyoku) to translate the Hash
into XML.

``` ruby
client.call(:authenticate, message: { username: 'luke', password: 'secret' })
```

For more complex XML structures, you can pass any other object that is not a Hash and responds
to `#to_s` if you want to use a more specific tool to build your request.

``` ruby
class ServiceRequest

  def to_s
    builder = Builder::XmlMarkup.new
    builder.instruct!(:xml, encoding: "UTF-8")

    builder.person { |b|
      b.username("luke")
      b.password("secret")
    }

    builder
  end

end

client.call(:authenticate, message: ServiceRequest.new)
```

#### message_tag

You can change the name of the SOAP message tag. If you need to use this option, please open an issue let me know why.

``` ruby
client.call(:authenticate, message_tag: :authenticationRequest)
```

This should be set by Savon if it has a WSDL. If it doesn't, it generates a message tag from the SOAP
operation name. Here's how the option changes the request.

``` xml
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:tns="http://v1.example.com/">
  <env:Body>
    <tns:authenticationRequest>
    </tns:authenticationRequest>
  </env:Body>
</env:Envelope>
```

#### attributes

The attributes option accepts a Hash of XML attributes for the SOAP message tag.

``` ruby
client.call(:authenticate, :attributes => { "ID" => "ABC321" })
```

Here's what the request will look like.

``` xml
<env:Envelope
    xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:tns="http://v1.example.com/">
  <env:Body>
    <tns:authenticationRequest ID="ABC321">
    </tns:authenticationRequest>
  </env:Body>
</env:Envelope>
```

If you need to use this option, please open an issue and provide you WSDL for debugging.
This should be handled automatically, but we need real world examples to do so.

#### xml

If you need to, you can even shortcut Savon's Builder and send your very own XML.

``` ruby
client.call(:authenticate, xml: "<envelope><body></body></envelope>")
```


### Locals: Response

#### advanced_typecasting

Savon by default tells [Nori](https://github.com/savonrb/nori) to use its "advanced typecasting" to convert XML values like
`"true"` to `TrueClass`, dates to date objects, etc.

``` ruby
client.call(:authenticate, advanced_typecasting: false)
```

#### response_parser

Savon defaults to [Nori's](https://github.com/savonrb/nori) Nokogiri parser. Nori ships with a REXML parser as an alternative.
If you need to switch to REXML, please open an issue and describe the problem you have with the Nokogiri parser.

``` ruby
client.call(:authenticate, response_parser: :rexml)
```


Errors
------

#### Savon::Error

The base class for all other Savon errors. This allows you to either rescue a specific error like `Savon::SOAPFault`
or rescue `Savon::Error` to catch them all.

#### Savon::SOAPFault

Raised when the server returns a SOAP fault error. The error object contains the [HTTPI](https://github.com/savonrb/httpi)
response for you to further investigate what went wrong.

``` ruby
def authenticate(credentials)
  client.call(:authenticate, message: credentials)
rescue Savon::SOAPFault => error
  Logger.log error.http.code
  raise
end
```

The example above rescues from SOAP faults, logs the HTTP response code and re-raises the SOAP fault.
You can also translate the SOAP fault response into a Hash.

``` ruby
def authenticate(credentials)
  client.call(:authenticate, message: credentials)
rescue Savon::SOAPFault => error
  fault_code = error.to_hash[:fault][:faultcode]
  raise CustomError, fault_code
end
```

#### Savon::HTTPError

Raised when Savon considers the HTTP response to be not successful. You can rescue this error and access the
[HTTPI](https://github.com/savonrb/httpi) response for investigation.

``` ruby
def authenticate(credentials)
  client.call(:authenticate, message: credentials)
rescue Savon::HTTPError => error
  Logger.log error.http.code
  raise
end
```

The example rescues from HTTP errors, logs the HTTP response code and re-raises the error.

#### Savon::InvalidResponseError

Raised when you try to access the response header or body of a response that is not a SOAP response as a Hash.
If the response is not an XML document with an envelope, a header and a body node, it's not accessible as a Hash.

``` ruby
def get_id_from_response(response)
  response.body[:return][:id]
rescue Savon::InvalidResponseError
  Logger.log "Invalid server response"
  raise
end
```


Response
--------

The response provides a few convenience methods for you to work with the XML in any way you want.

#### #header

Translates the response and returns the SOAP header as a Hash.

``` ruby
response.header  # => { token: "secret" }
```

#### #body

Translates the response and returns the SOAP body as a Hash.

``` ruby
response.body  # => { response: { success: true, name: "luke" } }
```

#### #hash

Translates the response and returns it as a Hash.

``` ruby
response.hash  # => { envelope: { header: { ... }, body: { ... } } }
```

Savon uses [Nori](http://rubygems.org/gems/nori) to translate the SOAP response XML to a Hash.
You can change how the response is translated through a couple of global and local options.
The following example shows the options available to configure Nori and their defaults.

``` ruby
client = Savon.client do
  # Savon defaults to strip namespaces from the response
  strip_namespaces true

  # Savon defaults to convert Hash key Symbols to lowerCamelCase XML tags
  convert_request_keys_to :camelcase
end

client.call(:operation) do
  # Savon defaults to activate "advanced typecasting"
  advanced_typecasting true

  # Savon defaults to the Nokogiri parser
  response_parser :nokogiri
end
```

These options map to Nori's options and you can find more information about how they work in
the [README](https://github.com/savonrb/nori/blob/master/README.md).

#### #to_xml

Returns the raw SOAP response.

``` ruby
response.to_xml  # => "<response><success>true</success><name>luke</name></response>"
```

#### #doc

Returns the SOAP response as a [Nokogiri](http://nokogiri.org/) document.

``` ruby
response.doc  # => #<Nokogiri::XML::Document:0x1017b4268 ...
```

#### #xpath

Delegates to [Nokogiri's xpath method](http://nokogiri.org/Nokogiri/XML/Node.html#method-i-xpath).

``` ruby
response.xpath("//v1:authenticateResponse/return/success").first.inner_text.should == "true"
```

#### #http

Returns the [HTTPI](https://github.com/savonrb/httpi) response.

``` ruby
response.http  # => #<HTTPI::Response:0x1017b4268 ...
```

In case you disabled the global `:raise_errors` option, you can ask the response for its state.

``` ruby
response.success?     # => false
response.soap_fault?  # => true
response.http_error?  # => false
```

Model
-----

`Savon::Model` can be used to model a class interface on top of a SOAP service. Extending any class
with this module will give you three class methods to configure the service model.

#### .client

Sets up the client instance used by the class.

Needs to be called before any other model class method to set up the Savon client with a `:wsdl` or
the `:endpoint` and `:namespace` of the service.

``` ruby
class User
  extend Savon::Model

  client wsdl: "http://example.com?wsdl"
  # or
  client endpoint: "http://example.com", namespace: "http://v1.example.com"
end
```

#### .global

Sets a global option to a given value.

If there are multiple arguments for an option (like an auth method requiering username and password),
you can pass those as separate arguments to the `.global` method instead of passing an Array.

``` ruby
class User
  extend Savon::Model

  client wsdl: "http://example.com?wsdl"

  global :open_timeout, 30
  global :basic_auth, "luke", "secret"
end
```

#### .operations

Defines class and instance methods for he given SOAP operations.

Use this method to specify which SOAP operations should be available through your service model.

``` ruby
class User
  extend Savon::Model

  client wsdl: "http://example.com?wsdl"

  global :open_timeout, 30
  global :basic_auth, "luke", "secret"

  operations :authenticate, :find_user

  def self.find_user(id)
    super(message: { id: id })
  end
end
```

For every SOAP operation, it creates both class and instance methods. All these methods call the
service with an optional Hash of local options and return a response.

``` ruby
# instance operations
user = User.new
response = user.authenticate(message: { username: "luke", secret: "secret" })

# class operations
response = User.find_user(1)
```

In the previous User class example, we're overwriting the `.find_user` operation and delegating to `super`
with a SOAP message Hash. You can do that both on the class and on the instance.


Examples
--------

Savon comes with a few [commented and easy to read integration (example) specs](https://github.com/savonrb/savon/tree/master/spec/integration)
for you to play with.


Observers
---------

Savon has one global way of adding observers to any request.

``` ruby
class Observer

  def notify(operation_name, builder, globals, locals)
    nil
  end

end

Savon.observers << Observer.new
```

Savon calls the `#notify` method of every observer in the order they were added and passes the name of
the operation that is being called, the builder which can be asked for the generated request XML and
any global and local options.

In the previous example, we're explicitly returning `nil` from the `#notify` method to allow Savon to
continue and execute the request. But you can also return an `HTTPI::Response` to mock the request.

``` ruby
class Observer

  def notify(operation_name, builder, globals, locals)
    code    = 200
    headers = {}
    body    = ""

    HTTPI::Response.new(code, headers, body)
  end

end

Savon.observers << Observer.new
```

Clear the observers if you don't need them.

``` ruby
Savon.observers.clear
```


Testing
-------

Testing integration with a SOAP service does not differ from testing integration with any other service.
There is really no "right way" of doing this, but from my experience, it's good to have both unit and
integration tests to strike a balance between test speed and reliability.

Where Savon 1.0 had [Savon::Spec](https://rubygems.org/gems/savon_spec) to mock SOAP requests, Savon 2.0
adds support for mocking requests on top of observers. Since it's always a good idea to wrap external
libraries, let's assume you created a simple class for talking to some kind of authentication service.

``` ruby
require "savon"

class AuthenticationService

  def initialize
    @client = Savon.client(wsdl: "http://example.com?wsdl")
  end

  def authenticate(message)
    @client.call(message: message)
  end

end
```

When you're using RSpec, you can include the `Savon::SpecHelper` module in your specs.
The helper module comes with a simple mock interface available through the `savon` method.
Instructions for MiniTest will be added asap.

``` ruby
require "spec_helper"

# require the helper module
require "savon/mock/spec_helper"

describe AuthenticationService do
  # include the helper module
  include Savon::SpecHelper

  # set Savon in and out of mock mode
  before(:all) { savon.mock!   }
  after(:all)  { savon.unmock! }

  describe "#authenticate" do
    it "authenticates the user with the service" do
      message = { username: "luke", password: "secret" }
      fixture = File.read("spec/fixtures/authentication_service/authenticate.xml")

      # set up an expectation
      savon.expects(:authenticate).with(message: message).returns(fixture)

      # call the service
      service = AuthenticationService.new
      response = service.authenticate(message)

      expect(response).to be_successful
    end
  end
end
```

As you can see in this example, you have to explicitly set Savon in and out of mock mode before and after
your specs. The example uses RSpec's `before` and `after` hooks for that.

#### Expectations

Are specified through the `#expects` method on the `savon` mock interface. It takes the
name of a SOAP operation that is expected to be called.

``` ruby
savon.expects(:authenticate)
```

#### Options

Can be tested through the `#with` method. This currently only supports checking the SOAP message,
but can easily be changed to support any global and or local option along with the generated request XML.
This is possible because Savon mocks the request as late as possible to ensure everything works as expected
in your integration tests.

If you're trying to "stub" a request, you can simply leave out the `#with` method, but you need to call the
`#returns` method to return a response that Savon can work with.

``` ruby
message = { username: "luke", password: "secret" }
savon.expects(:authenticate).with(message: message)
```

#### Fixtures

Should match a recorded SOAP response from the server for the request you're testing.
The `#returns` method accepts a few options which are used to create an HTTPI response.

``` ruby
message = { username: "luke", password: "secret" }
fixture = File.read("spec/fixtures/authentication_service/authenticate.xml")

savon.expects(:authenticate).with(message: message).returns(fixture)
```

When passed a String, like in the example above, the `#returns` method defaults to a response code of 200
with no headers and uses the String as the response body. You can also pass a Hash to specify all values
yourself. This can be useful if you're testing SOAP fault responses which have a response code of 500.

``` ruby
soap_fault = File.read("spec/fixtures/authentication_service/soap_fault.xml")

response = { code: 500, headers: {}, body: soap_fault }
savon.expects(:authenticate).with(message: message).returns(response)
```

This is a brand new feature, so please give it a try and let me know what you think.


Changes
-------

A probably incomplete list of changes to help you migrate your application. Let me know if you think there's
something missing.

#### Savon.config

Was removed to better support concurrent usage and allow to use Savon in multiple different
configurations in a single project.

#### Logger

Was replaced with Ruby's standard Logger. The custom Logger was removed for simplicity. You can
still set the global `:log_level` and `:filters` options or active `:pretty_print_xml`.

#### Hooks

Are no longer supported. The implementation was way too complex and still didn't properly solve the
problem of serving as a mock-helper for the [Savon::Spec](http://rubygems.org/gems/savon_spec) gem. If you used
them for any other purpose, please open an issue and we may find a better solution.

#### Nori

Was updated to remove global state. All Nori 2.0 options are now encapsulated and can be configured
through Savon's options. This allows to use Nori in multiple different configurations in a project that uses Savon.

#### Gyoku

Was also updated to remove global state. All Gyoku 1.0 options are encapsulated and can be configured
through Savon. Instead of `Gyoku.convert_symbols_to`, please use the global `:convert_request_keys_to` option.

#### HTTPI

Was updated to version 2 which comes with [support for EM-HTTPRequest](https://github.com/savonrb/httpi/pull/40).

#### NTLM authentication

Support will probably be added in the next version. This really needs some good specs
and integration tests first.

#### WSSE signature

Was not covered with specs and has been removed. If anyone uses this and wants to provide a
properly tested implementation, please talk to me.

#### response[]

The Hash-like read-access to the response was removed.

#### Savon::SOAP::Fault

Was renamed to `Savon::SOAPFault`.

#### Savon::HTTP::Error

Was renamed to `Savon::HTTPError`.

#### Savon::SOAP::InvalidResponseError

Was renamed to `Savon::InvalidResponseError`.

