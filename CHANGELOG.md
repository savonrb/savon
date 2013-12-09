### 2.3.2 (2013-12-09)

* Fix: [#520](https://github.com/savonrb/savon/issues/520) Fixes a regression in message tags in requests and responses.

### 2.3.1 (2013-12-05)

* Removed dependency on Nokogiri <= 1.4 -- This improves support for ruby 1.9.3 and 2.0.0 and officially begins the end of support for ruby 1.8.7
  See [issue #487](https://github.com/savonrb/savon/issues/487)

### 2.3.0 (2013-07-27)

Combined release ticket: [#481](https://github.com/savonrb/savon/issues/481)

* Feature: [#405](https://github.com/savonrb/savon/issues/405) Improved NTLM support based on HTTPI v2.1.0.

* Feature: [#424](https://github.com/savonrb/savon/issues/424) Adds support for multipart responses
  through the updated [savon-multipart](https://github.com/savonrb/savon-multipart) gem. You can now
  specify `multipart: true` either as a global or local option. Please make sure you have the
  updated `savon-multipart` gem installed and loaded, as it is not a direct dependency of Savon.

    ``` ruby
    require 'savon'
    require 'savon-multipart'

    # expect multipart responses for every operation
    client = Savon.client(wsdl: wsdl, multipart: true)

    # only expect a multipart response for this operation
    client.call(:my_operation, multipart: true)
    ```

* Feature: [#470](https://github.com/savonrb/savon/issues/470) Added a local `:soap_header` option
  to allow setting the SOAP header per request.

* Feature: [#402](https://github.com/savonrb/savon/issues/402) Makes it possible to create mocks
  that don't care about the message sent by using `:any` for the `:message` option.

    ``` ruby
    savon.expects(:authenticate).with(message: :any)
    ```

* Fix: [#450](https://github.com/savonrb/savon/pull/450) Added `Savon::Response#soap_fault`
  and `Savon::Response#http_error` which were present in version 1.

* Fix: [#474](https://github.com/savonrb/savon/issues/474) Changed `Savon::Response#header` and
  `Savon::Response#body` to respect the global `:convert_response_tags_to` and `:strip_namespaces`
  options and return the expected result instead of raising a `Savon::InvalidResponseError`.

* Fix: [#461](https://github.com/savonrb/savon/issues/461) Fixed two problems related to namespace
  qualified messages and the element `:order!`.

* Fix: [#476](https://github.com/savonrb/savon/issues/476) fixes a problem where the namespace
  for the message tag was not correctly determined from the WSDL.

* Fix: [#468](https://github.com/savonrb/savon/issues/468) Changed the dependency on Nokogiri
  to < 1.6, because Nokogiri 1.6 dropped support for Ruby 1.8.

### 2.2.0 (2013-04-21)

* Feature: [#416](https://github.com/savonrb/savon/pull/416) The global `namespace_identifier`
  option can now be set to `nil` to not add a namespace identifier to the message tag.

* Feature: [#408](https://github.com/savonrb/savon/pull/408) Added `Savon::Client#service_name`
  to return the name of the SOAP service.

* Improvement: When mistyping an option name, Savon used to raise a simple `NoMethodError`.
  This is because regardless of whether you're using the Hash or block syntax to pass global
  or local options, both are just method calls on some options object.

    ``` ruby
    NoMethodError: undefined method 'wsdk' for #<Savon::GlobalOptions:0x007fed95a55228>
    ```

  As of this change, Savon now catches those errors and raise a `Savon::UnknownOptionError`
  with a slightly more helpful error message instead.

    ``` ruby
    Savon::UnknownOptionError:
       Unknown global option: :wsdk
    ```

* Improvement: [#385](https://github.com/savonrb/savon/issues/385) Instead of raising an
  `ArgumentError` when Wasabi can't find any operations in the WSDL. Savon now raises a
  `Savon::UnknownOperationError`. This might happen when Wasabi fails to parse the WSDL
  because of imports for example.

* Fix: [#430](https://github.com/savonrb/savon/pull/430) allows you to rescue and ignore
  `Savon::Error` errors in production while still having mocks trigger test failures.

* Fix: [#393](https://github.com/savonrb/savon/pull/393) changed `Savon::SOAPFault` to work
  with generic response Hash keys.

* Fix: [#423](https://github.com/savonrb/savon/issues/423) fixes a problem where Wasabi was
  not able to find extension base elements defined in imports it didn't follow.

### 2.1.0 (2013-02-03)

* Feature: [#372](https://github.com/savonrb/savon/pull/372) added global `ssl_cert_key_password` option.

* Feature: [#361](https://github.com/savonrb/savon/issues/361) added the local `:attributes`
  option to allow adding XML attributes to the SOAP message tag.

* Improvement: [#363](https://github.com/savonrb/savon/issues/363) Savon 2.0 remembers the cookies from
  the last response and passes it to the next request, which is not a proper way to handle cookies.
  I removed this behavior and introduced an easy way to handle cookies manually instead.

* Improvement: [#380](https://github.com/savonrb/savon/pull/380) changed the gemspec to not rely on git.

* Fix: [#378](https://github.com/savonrb/savon/pull/378) use the proxy option for WSDL requests.

* Fix: [#369](https://github.com/savonrb/savon/pull/369) use HTTP basic and digest authentication
  credentials to retrieve WSDL files.
  Fixes [#367](https://github.com/savonrb/savon/issues/367#issuecomment-12720307).

* Fix: [#349](https://github.com/savonrb/savon/issues/349) global timeout and SSL options are
  now used to retrieve a remote WSDL document.

* Fix: [#353](https://github.com/savonrb/savon/issues/353) simplified logging. the global `:log`
  option is now only used to store whether Savon should log instead of creating a new `Logger`
  and changing its logdev to `$stdout` or `/dev/null` depending on the what was passed.

  This also fixes [rubiii/savon#2](https://github.com/rubiii/savon/issues/2) and
  [#379](https://github.com/savonrb/savon/issues/379).

* Fix: [#376](https://github.com/savonrb/savon/issues/376) added a global `namespaces` option
  for adding namespaces to the SOAP envelope.

### 2.0.3 (2013-01-19)

* Upgraded Nori dependency to prevent people from using a version that is vulnerable to
  the recent [remote code execution bug](https://gist.github.com/4532291).

### 2.0.2 (2012-12-20)

* Fix: [#297](https://github.com/savonrb/savon/issues/297#issuecomment-11536517) added the global
  `:ssl_verify_mode` and `:ssl_version` options which were missing.

* Fix: [#344](https://github.com/savonrb/savon/issues/344) added missing global ssl cert options
  `:ssl_cert_file`, `:ssl_cert_key_file` and `:ssl_ca_cert_file`.

### 2.0.1 (2012-12-19)

* Fix [#342](https://github.com/savonrb/savon/issues/342) fixes an issue where namespaces could
  not be resolved if the actual operation name to call did not match the operation name passed
  to the client's `#call` method. For example: `:get_stations` for a `getStations` operation.

### 2.0.0 (2012-12-18)

* Read about all the changes in the [updated documentation](http://savonrb.com/version2.html).

* Fix: [#322](https://github.com/savonrb/savon/issues/322) use the builder's state instead of the
  block's return value to set the soap body/xml values.

* Fix: [#327](https://github.com/savonrb/savon/issues/327) `response.to_array` now properly
  returns FalseClass values.

* Fix: [320](https://github.com/savonrb/savon/issues/320) use the correct SOAP namespace when the
  SOAP version changes between requests.

* Fix: [321](https://github.com/savonrb/savon/issues/321) preserve `[false]` values in Hashes.

### 1.2.0 (2012-09-15)

* Fix: [#312](https://github.com/savonrb/savon/pull/312) recursively determines the proper namespaces
  for SOAP body Hashes with nested Arrays of Hashes.

* Improvement: [#318](https://github.com/savonrb/savon/pull/318) isolates building the request to
  improve threadsafety.

* Refactoring: Use the `Wasabi::Document` with resolver instead of the custom `Savon::Wasabi::Document`.

### 1.1.0 (2012-06-28)

* Improvement: Changed Savon's core dependencies to be more strict and only allow bug fix changes.
  Major or minor releases of these dependencies now need a release of Savon so they can be used.
  This should improve the stability of the library and make it easier to update, because changes
  to these core dependencies will be documented here as well.

* Fix: The latest version of Wasabi should now correctly detect the names of your operations.
  So you should be able to just get the names of some operation:

    ``` ruby
    client.wsdl.soap_actions
    # => [:authenticate, :find_user]
    ```

    and pass the Symbol to execute a request:

    ``` ruby
    client.request :authenticate, body: { token: "secret" }
    ```

    If you still pass anything other than a single Symbol to that method, please open an issue!
    You shouldn't need to specify a namespace or additional attributes for the tag.

* Refactoring: Moved code that sets the cookies from the last response for the
  next request to `HTTPI::Request#set_cookies`.

### 1.0.0 (2012-06-09)

* Fix: `Savon.client` didn't pass the optional block.

* Improvement: [#291](https://github.com/savonrb/savon/issues/291) changed the `:soap_request` hook to act
  like an around filter. The hook now receives a callback block to execute the SOAP call and can return
  the result of the callback to continue the request. It can also not call the callback block and return
  some `HTTPI::Response` to mock the SOAP request.

    As this change affects `savon_spec`, you need to update `savon_spec` to v1.3.0.

### 0.9.14 (2012-06-07)

* Fix: [#292](https://github.com/savonrb/savon/issues/292) again

### 0.9.13 (2012-06-07)

* Fix: [#292](https://github.com/savonrb/savon/issues/292)

### 0.9.12 (2012-06-07)

* Re-added the log method setters to the new config object for backwards compatibility.
  You should be able to configure the logger as you used to do.

    ``` ruby
    Savon.configure do |config|
      config.log = false            # disable logging
      config.log_level = :info      # changing the log level
      config.logger = Rails.logger  # using the Rails logger
    end
    ```

### 0.9.11 (2012-06-06)

* Feature: [#264](https://github.com/savonrb/savon/pull/264) - Thanks to @hoverlover, Savon and Akami now support
  signed messages through WSSE.

* Fix: [#275](https://github.com/savonrb/savon/pull/275) - Add namespaces to keys in both the SOAP body hash as well
  as any keys specified in a :order! Array instead of having to define them manually.

* Fix: [#257](https://github.com/savonrb/savon/issues/257) - Add ability to accept and send multiple cookies.

* Improvement: [#277](https://github.com/savonrb/savon/pull/277) automatically namespace the SOAP input tag.
  Here's an example from the pull request:

    ``` ruby
    client.request :authenticate
    ```

    Note the automatic namespace identifier on the authenticate element, as well as the proper namespace inclusion
    in the document:

    ``` xml
    <env:Envelope
        xmlns:xsd="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:tns="http://v1_0.ws.auth.order.example.com/"
        xmlns:env="http://schemas.xmlsoap.org/soap/envelope/">

        <tns:authenticate>
            <tns:user>username</tns:user>
            <tns:password>password</tns:password>
        </tns:authenticate>
    </env:Envelope>
    ```

### 0.9.10 (2012-06-06)

* Feature: [#289](https://github.com/savonrb/savon/pull/289) - Allow the SOAP envelope header to be set as a String.

* Feature: In addition to the global configuration, there's now also one configuration per client.
  The global config is cloned when a new client is initialized and gets used instead of the global one.
  In addition, for `Savon::Model` classes, the config is cloned per class.

    Closes [#84](https://github.com/savonrb/savon/issues/84) by allowing one logger per client and
    [#270](https://github.com/savonrb/savon/issues/270) by allowing to specify error handling per client.

* Feature: Added an option to pretty print XML in log messages. Closes [#256](https://github.com/savonrb/savon/issues/256)
  and [#280](https://github.com/savonrb/savon/issues/280).

    ``` ruby
    # global
    Savon.configure do |config|
      config.pretty_print_xml = true
    end

    # per client
    client.config.pretty_print_xml = true
    ```

* Refactoring:
  * Added `Savon.client` as a shortcut for creating a new `Savon::Client`
  * Changed `Savon::Config` from a module to a class.
  * Moved logging to the new `Savon::Logger` object.
  * Removed the `blank?` extension from `Object`.

### 0.9.9 (2012-02-17)

* Improvement: [pull request 255](https://github.com/savonrb/savon/pull/255) - Raise an error if fetching
  a remote WSDL fails. Possible fix for [issue 236](https://github.com/savonrb/savon/issues/236).

* Improvement: The value for elementFormDefault (:unqualified, :qualified) can now be specified when creating
  a `Savon::Client`. For example:

    ``` ruby
    Savon::Client.new do
      wsdl.element_form_default = :unqualified
    end
    ```

* Improvement: [pull request 263](https://github.com/savonrb/savon/pull/263) - The SOAP action can now be set
  via a `:soap_action` key passed to the `#request` method.

    ``` ruby
    client.request(:get_user, :soap_action => :test_action)
    ```

* Fix: [pull request 265](https://github.com/savonrb/savon/pull/265) - Fixes gemspec problems when bundling
  under JRuby 1.6.5. Also fixes [issue 267](https://github.com/savonrb/savon/issues/267).

### 0.9.8 (2012-02-15)

* Feature: Savon now ships with [Savon::Model](http://rubygems.org/gems/savon_model).
  Savon::Model is a lightweight DSL to be used inside your domain models. It's been refactored
  and is now [even more useful](http://savonrb.com/#how_to_date_a_model) than before.

* Feature: Merged [pull request 230](https://github.com/savonrb/savon/pull/230) to allow filtering values
  in logged SOAP request XML messages.

    ``` ruby
    Savon.configure do |config|
      config.log_filter = ["password"]
    end
    ```

* Feature: Added an option to change the default encoding of the XML directive tag (defaults to UTF-8)
  to fix [issue 234](https://github.com/savonrb/savon/issues/234).

    ``` ruby
    client.request(:find_user) do
      soap.encoding = "UTF-16"
      soap.body = { :id => 1 }
    end
    ```

* Improvement: Merged [pull request 231](https://github.com/savonrb/savon/pull/231) to gracefully handle
  invalid response bodies by throwing a `Savon::SOAP::InvalidResponseError`.

* Fix: [issue 237](https://github.com/savonrb/savon/issues/237) - Set the Content-Type and Content-Length
  headers for every request.

* Fix: [pull request 250](https://github.com/savonrb/savon/pull/250) - The Content-Length header should
  be the size in bytes.

### 0.9.7 (2011-08-25)

* Feature: Merged [pull request 210](https://github.com/savonrb/savon/pull/210) by
  [mboeh](https://github.com/mboeh) to add `Savon::SOAP::Response#doc` and
  `Savon::SOAP::Response#xpath`.

* Feature: Merged [pull request 211](https://github.com/savonrb/savon/pull/211) by
  [mattkirman](https://github.com/mattkirman) to fix [issue 202](https://github.com/savonrb/savon/issues/202).

* Feature: You can now pass a block to `Savon::SOAP::XML#body` and use Builder to create the XML:

    ``` ruby
    client.request(:find) do
      soap.body do |xml|
        xml.user do
          xml.id 601173
        end
      end
    end
    ```

* Fix: [issue 218](https://github.com/savonrb/savon/pull/218) - Savon now correctly handles namespaced
  Array items in a Hash passed to `Savon::SOAP::XML#body=`.

* Fix: Merged [pull request 212](https://github.com/savonrb/savon/pull/212) to fix
  [savon_spec issue 2](https://github.com/savonrb/savon_spec/issues/2).

* Improvement: [issue 222](https://github.com/savonrb/savon/issues/222) - Set the Content-Length header.

### 0.9.6 (2011-07-07)

* Improvement/Fix: Updated Savon to use the latest version of [Wasabi](http://rubygems.org/gems/wasabi).
  This should fix [issue 155](https://github.com/savonrb/savon/issues/155) - Savon can automatically add namespaces
  to SOAP requests based on the WSDL. Users shouldn't need to do anything differently or even notice whether their WSDL
  hits this case; the intention is that this will "Just Work" and follow the WSDL. The SOAP details are that if
  elementFormDefault is specified as qualified, Savon will automatically prepend the correct XML namespaces to the
  elements in a SOAP request. Thanks to [jkingdon](https://github.com/jkingdon) for this.

* Fix: [issue 143](https://github.com/savonrb/savon/issues/143) - Updating Wasabi should solve this issue.

### 0.9.5 (2011-07-03)

* Refactoring: Extracted WSSE authentication out into the [akami](http://rubygems.org/gems/akami) gem.

### 0.9.4 (2011-07-03)

* Refactoring: Extracted the WSDL parser out into the [wasabi](http://rubygems.org/gems/wasabi) gem.
  This should isolate upcoming improvements to the parser.

### 0.9.3 (2011-06-30)

* Fix: [issue 138](https://github.com/savonrb/savon/issues/138) -
  Savon now supports setting a global SOAP header via `Savon.soap_header=`.

* Fixed the namespace for wsse message timestamps from `wsse:Timestamp`
  to `wsu:Timestamp` as required by the specification.

* Change: Removed support for NTLM authentication until it's stable. If you need it, you can still
  add the following line to your Gemfile:

    ``` ruby
    gem "httpi", "0.9.4"
    ```

* Refactoring:

  * `Hash#map_soap_response` and some of its helpers are moved to [Nori v1.0.0](http://rubygems.org/gems/nori/versions/1.0.0).
    Along with replacing core extensions with a proper implementation, Nori now contains a number of methods
    for [configuring its default behavior](https://github.com/savonrb/nori/blob/master/CHANGELOG.md):

      * The option whether to strip namespaces was moved to Nori.strip_namespaces
      * You can disable "advanced typecasting" for SOAP response values
      * And you can configure how SOAP response keys should be converted

  * `Savon::SOAP::XML.to_hash`, `Savon::SOAP::XML.parse` and `Savon::SOAP::XML.to_array` are gone.
    It wasn't worth keeping them around, because they didn't do much. You can simply parse a SOAP
    response and translate it to a Savon SOAP response Hash via:

        ``` ruby
        Nori.parse(xml)[:envelope][:body]
        ```

  * `Savon::SOAP::Response#basic_hash` is now `Savon::SOAP::Response#hash`.

### 0.9.2 (2011-04-30)

* Fix: [issue 154](https://github.com/savonrb/savon/pull/154) -
  Timezone format used by Savon now matches the XML schema spec.

* Improvement: WSSE basic, digest and timestamp authentication are no longer mutually exclusive.
  Thanks to [mleon](https://github.com/mleon) for solving [issue #142](https://github.com/savonrb/savon/issues/142).

* Improvement: Switched from using Crack to translate the SOAP response to a Hash to using
  [Nori](http://rubygems.org/gems/nori). It's based on Crack and comes with pluggable parsers.
  It defaults to REXML, but you can switch to Nokogiri via:

    ``` ruby
    Nori.parser = :nokogiri
    ```

* Improvement: WSDL parsing now uses Nokogiri instead of REXML.

### 0.9.1 (2011-04-06)

* Improvement: if you're only setting the local or remote address of your wsdl document, you can
  now pass an (optional) String to `Savon::Client.new` to set `wsdl.document`.

    ``` ruby
    Savon::Client.new "http://example.com/UserService?wsdl"
    ```

* Improvement: instead of calling the `to_hash` method of your response again and again and again,
  there is now a `#[]` shortcut for you.

    ``` ruby
    response[:authenticate_response][:return]
    ```

### 0.9.0 (2011-04-05)

* Feature: issues [#158](https://github.com/savonrb/savon/issues/158),
  [#169](https://github.com/savonrb/savon/issues/169) and [#172](https://github.com/savonrb/savon/issues/172)
  configurable "Hash key Symbol to lowerCamelCase" conversion by using the latest version of
  [Gyoku](http://rubygems.org/gems/gyoku).

    ``` ruby
    Gyoku.convert_symbols_to(:camelcase)
    Gyoku.xml(:first_name => "Mac")  # => "<FirstName></Firstname>"
    ```

    You can even define your own conversion formular.

    ``` ruby
    Gyoku.convert_symbols_to { |key| key.upcase }
    Gyoku.xml(:first_name => "Mac")  # => "<FIRST_NAME></FIRST_NAME>"
    ```

    This should also work for the SOAP input tag and SOAPAction header. So if you had to use a String for
    the SOAP action to call because your services uses CamelCase instead of lowerCamelCase, you can now
    change the default and use Symbols instead.

    ``` ruby
    Gyoku.convert_symbols_to(:camelcase)

    # pre Gyoku 0.4.0
    client.request(:get_user)  # => "<getUser/>
    client.request("GetUser")  # => "<GetUser/>"

    # post Gyoku 0.4.0
    client.request(:get_user)  # => "<GetUser/>"
    ```

* Improvement: issues [#170](https://github.com/savonrb/savon/issues/170) and
  [#173](https://github.com/savonrb/savon/issues/173) Savon no longer rescues exceptions raised by
  `Crack::XML.parse`. If Crack complains about your WSDL document, you should take control and
  solve the problem instead of getting no response.

* Improvement: issue [#172](https://github.com/savonrb/savon/issues/172) support for global env_namespace.

    ``` ruby
    Savon.configure do |config|
      config.env_namespace = :soapenv  # changes the default :env namespace
    end
    ```

* Fix: [issue #163](https://github.com/savonrb/savon/issues/163) "Savon 0.8.6 not playing nicely
  with Httpi 0.9.0". Updating HTTPI to v0.9.1 should solve this problem.

* And if you haven't already seen the new documentation: [savonrb.com](http://savonrb.com)

### 0.8.6 (2011-02-15)

* Fix for issues [issue #147](https://github.com/savonrb/savon/issues/147) and [#151](https://github.com/savonrb/savon/issues/151)
  ([771194](https://github.com/savonrb/savon/commit/771194)).

### 0.8.5 (2011-01-28)

* Fix for [issue #146](https://github.com/savonrb/savon/issues/146) ([98655c](https://github.com/savonrb/savon/commit/98655c)).

* Fix for [issue #147](https://github.com/savonrb/savon/issues/147) ([252670](https://github.com/savonrb/savon/commit/252670)).

### 0.8.4 (2011-01-26)

* Fix for issues [issue #130](https://github.com/savonrb/savon/issues/130) and [#134](https://github.com/savonrb/savon/issues/134)
  ([4f9847](https://github.com/savonrb/savon/commit/4f9847)).

* Fix for [issue #91](https://github.com/savonrb/savon/issues/91) ([5c8ec1](https://github.com/savonrb/savon/commit/5c8ec1)).

* Fix for [issue #135](https://github.com/savonrb/savon/issues/135) ([c9261d](https://github.com/savonrb/savon/commit/c9261d)).

### 0.8.3 (2011-01-11)

* Moved implementation of `Savon::SOAP::Response#to_array` to a class method at `Savon::SOAP::XML.to_array`
  ([05a7d3](https://github.com/savonrb/savon/commit/05a7d3)).

* Fix for [issue #131](https://github.com/savonrb/savon/issues/131) ([4e57b3](https://github.com/savonrb/savon/commit/4e57b3)).

### 0.8.2 (2011-01-04)

* Fix for [issue #127](https://github.com/savonrb/savon/issues/127) ([0eb3da](https://github.com/savonrb/savon/commit/0eb3da4)).

* Changed `Savon::WSSE` to be based on a Hash instead of relying on builder ([4cebc3](https://github.com/savonrb/savon/commit/4cebc3)).

    `Savon::WSSE` now supports wsse:Timestamp headers ([issue #122](https://github.com/savonrb/savon/issues/122)) by setting
    `Savon::WSSE#timestamp` to `true`:

    ``` ruby
    client.request :some_method do
      wsse.timestamp = true
    end
    ```

     or by setting `Savon::WSSE#created_at` or `Savon::WSSE#expires_at`:

    ``` ruby
    client.request :some_method do
      wsse.created_at = Time.now
      wsse.expires_at = Time.now + 60
    end
    ```

    You can also add custom tags to the WSSE header ([issue #69](https://github.com/savonrb/savon/issues/69)):

    ``` ruby
    client.request :some_method do
      wsse["wsse:Security"]["wsse:UsernameToken"] = { "Organization" => "ACME", "Domain" => "acme.com" }
    end
    ```

### 0.8.1 (2010-12-22)

* Update to depend on HTTPI v0.7.5 which comes with a fallback to use Net::HTTP when no other adapter could be required.

* Fix for [issue #72](https://github.com/savonrb/savon/issues/72) ([22074a](https://github.com/savonrb/savon/commit/22074a8)).

* Loosen dependency on builder. Should be quite stable.

### 0.8.0 (2010-12-20)

* Added `Savon::SOAP::XML#env_namespace` ([51fa0e](https://github.com/savonrb/savon/commit/51fa0e)) to configure
  the SOAP envelope namespace. It defaults to :env but can also be set to an empty String for SOAP envelope
  tags without a namespace.

* Replaced quite a lot of core extensions by moving the Hash to XML translation into a new gem called
  [Gyoku](http://rubygems.org/gems/gyoku) ([bac4b4](https://github.com/savonrb/savon/commit/bac4b4)).

### 0.8.0.beta.4 (2010-11-20)

* Fix for [issue #107](https://github.com/savonrb/savon/issues/107) ([1d6eda](https://github.com/savonrb/savon/commit/1d6eda)).

* Fix for [issue #108](https://github.com/savonrb/savon/issues/108)
  ([f64400...0aaca2](https://github.com/savonrb/savon/compare/f64400...0aaca2)) Thanks [fagiani](https://github.com/fagiani).

* Replaced `Savon.response_pattern` with a slightly different implementation of the `Savon::SOAP::Response#to_array` method
  ([6df6a6](https://github.com/savonrb/savon/commit/6df6a6)). The method now accepts multiple arguments representing the response
  Hash keys to traverse and returns the result as an Array or an empty Array in case the key is nil or does not exist.

    ``` ruby
    response.to_array :get_user_response, :return
    # => [{ :id => 1, :name => "foo"}, { :id => 2, :name => "bar"}]
    ```

### 0.8.0.beta.3 (2010-11-06)

* Fix for [savon_spec](http://rubygems.org/gems/savon_spec) to not send nil to `Savon::SOAP::XML#body`
  ([c34b42](https://github.com/savonrb/savon/commit/c34b42)).

### 0.8.0.beta.2 (2010-11-05)

* Added `Savon.response_pattern` ([0a12fb](https://github.com/savonrb/savon/commit/0a12fb)) to automatically walk deeper into
  the SOAP response Hash when a pattern (specified as an Array of Regexps and Symbols) matches the response. If for example
  your response always looks like ".+Response/return" as in:

    ``` xml
      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <ns2:authenticateResponse xmlns:ns2="http://v1_0.ws.user.example.com">
            <return>
              <some>thing</some>
            </return>
          </ns2:authenticateResponse>
        </soap:Body>
      </soap:Envelope>
    ```

    you could set the response pattern to:

    ``` ruby
    Savon.configure do |config|
      config.response_pattern = [/.+_response/, :return]
    end
    ```

    then instead of calling:

    ``` ruby
    response.to_hash[:authenticate_response][:return]  # :some => "thing"
    ```

    to get the actual content, Savon::SOAP::Response#to_hash will try to apply given the pattern:

    ``` ruby
    response.to_hash  # :some => "thing"
    ```

    Please notice, that if you don't specify a response pattern or if the pattern doesn't match the
    response, Savon will behave like it always did.

* Added `Savon::SOAP::Response#to_array` (which also uses the response pattern).

### 0.8.0.beta.1 (2010-10-29)

* Changed `Savon::Client.new` to accept a block instead of multiple Hash arguments. You can access the
  wsdl, http and wsse objects inside the block to configure your client for a particular service.

    ``` ruby
    # Instantiating a client to work with a WSDL document
    client = Savon::Client.new do
      wsdl.document = "http://example.com?wsdl"
    end
    ```

    ``` ruby
    # Directly accessing the SOAP endpoint
    client = Savon::Client.new do
      wsdl.endpoint = "http://example.com"
      wsdl.namespace = "http://v1.example.com"
    end
    ```

* Fix for [issue #77](https://github.com/savonrb/savon/issues/77), which means you can now use
  local WSDL documents:

    ``` ruby
    client = Savon::Client.new do
      wsdl.document = "../wsdl/service.xml"
    end
    ```

* Changed the way SOAP requests are being dispatched. Instead of using method_missing, you now use
  the new `request` method, which also accepts a block for you to access the wsdl, http, wsse and
  soap object. Please notice, that a new soap object is created for every request. So you can only
  access it inside this block.

    ``` ruby
    # A simple request to an :authenticate method
    client.request :authenticate do
      soap.body = { :id => 1 }
    end
    ```

* The new `Savon::Client#request` method fixes issues [#37](https://github.com/savonrb/savon/issues/37),
  [#61](https://github.com/savonrb/savon/issues/61) and [#64](https://github.com/savonrb/savon/issues/64),
  which report problems with namespacing the SOAP input tag and attaching attributes to it.
  Some usage examples:

    ``` ruby
    client.request :get_user                  # Input tag: <getUser>
    client.request :wsdl, "GetUser"           # Input tag: <wsdl:GetUser>
    client.request :get_user :active => true  # Input tag: <getUser active="true">
    ```

* Savon's new `request` method respects the given namespace. If you don't give it a namespace,
  Savon will set the target namespace to "xmlns:wsdl". But if you do specify a namespace, it will
  be set to the given Symbol.

* Refactored Savon to use the new [HTTPI](http://rubygems.org/gems/httpi) gem.
  `HTTPI::Request` replaces the `Savon::Request`, so please make sure to have a look
  at the HTTPI library and let me know about any problems. Using HTTPI actually
  fixes the following two issues.

* Savon now adds both "xmlns:xsd" and "xmlns:xsi" namespaces for you. Thanks Averell.
  It also properly serializes nil values as xsi:nil = "true".

* Fix for [issue #24](https://github.com/savonrb/savon/issues/24).
  Instead of Net/HTTP, Savon now uses HTTPI to execute HTTP requests.
  HTTPI defaults to use HTTPClient which supports HTTP digest authentication.

* Fix for [issue #76](https://github.com/savonrb/savon/issues/76).
  You now have to explicitly specify whether to use a WSDL document, when instantiating a client.

* Fix for [issue #75](https://github.com/savonrb/savon/issues/75).
  Both `Savon::SOAP::Fault` and `Savon::HTTP::Error` now contain the `HTTPI::Response`.
  They also inherit from `Savon::Error`, making it easier to rescue both at the same time.

* Fix for [issue #87](https://github.com/savonrb/savon/issues/87).
  Thanks to Leonardo Borges.

* Fix for [issue #81](https://github.com/savonrb/savon/issues/81).
  Replaced `Savon::WSDL::Document#to_s` with a `to_xml` method.

* Fix for issues [#85](https://github.com/savonrb/savon/issues/85) and [#88](https://github.com/savonrb/savon/issues/88).

* Fix for [issue #80](https://github.com/savonrb/savon/issues/80).

* Fix for [issue #60](https://github.com/savonrb/savon/issues/60).

* Fix for [issue #96](https://github.com/savonrb/savon/issues/96).

* Removed global WSSE credentials. Authentication needs to be set up for each client instance.

* Started to remove quite a few core extensions.

### 0.7.9 (2010-06-14)

* Fix for [issue #53](https://github.com/savonrb/savon/issues/53).

### 0.7.8 (2010-05-09)

* Fixed gemspec to include missing files in the gem.

### 0.7.7 (2010-05-09)

* SOAP requests now start with a proper XML declaration.

* Added support for gzipped requests and responses (http://github.com/lucascs). While gzipped SOAP
  responses are decoded automatically, you have to manually instruct Savon to gzip SOAP requests:

    ``` ruby
    client = Savon::Client.new "http://example.com/UserService?wsdl", :gzip => true
    ```

* Fix for [issue #51](https://github.com/savonrb/savon/issues/51). Added the :soap_endpoint option to
  `Savon::Client.new` which lets you specify a SOAP endpoint per client instance:

    ``` ruby
    client = Savon::Client.new "http://example.com/UserService?wsdl",
      :soap_endpoint => "http://localhost/UserService"
    ```

* Fix for [issue #50](https://github.com/savonrb/savon/issues/50). Savon still escapes special characters
  in SOAP request Hash values, but you can now append an exclamation mark to Hash keys specifying that
  it's value should not be escaped.

### 0.7.6 (2010-03-21)

* Moved documentation from the Github Wiki to the actual class files and established a much nicer
  documentation combining examples and implementation (using Hanna) at: http://savon.rubiii.com

* Added `Savon::Client#call` as a workaround for dispatching calls to SOAP actions named after
  existing methods. Fix for [issue #48](https://github.com/savonrb/savon/issues/48).

* Add support for specifying attributes for duplicate tags (via Hash values as Arrays).
  Fix for [issue #45](https://github.com/savonrb/savon/issues/45).

* Fix for [issue #41](https://github.com/savonrb/savon/issues/41).

* Fix for issues [#39](https://github.com/savonrb/savon/issues/39) and [#49](https://github.com/savonrb/savon/issues/49).
  Added `Savon::SOAP#xml` which let's you specify completely custom SOAP request XML.

### 0.7.5 (2010-02-19)

* Fix for [issue #34](https://github.com/savonrb/savon/issues/34).

* Fix for [issue #36](https://github.com/savonrb/savon/issues/36).

* Added feature requested in [issue #35](https://github.com/savonrb/savon/issues/35).

* Changed the key for specifying the order of tags from :@inorder to :order!

### 0.7.4 (2010-02-02)

* Fix for [issue #33](https://github.com/savonrb/savon/issues/33).

### 0.7.3 (2010-01-31)

* Added support for Geotrust-style WSDL documents (Julian Kornberger <github.corny@digineo.de>).

* Make HTTP requests include path and query only. This was breaking requests via proxy as scheme and host
  were repeated (Adrian Mugnolo <adrian@mugnolo.com>)

* Avoid warning on 1.8.7 and 1.9.1 (Adrian Mugnolo <adrian@mugnolo.com>).

* Fix for [issue #29](https://github.com/savonrb/savon/issues/29).
  Default to UTC to xs:dateTime value for WSSE authentication.

* Fix for [issue #28](https://github.com/savonrb/savon/issues/28).

* Fix for [issue #27](https://github.com/savonrb/savon/issues/27). The Content-Type now defaults to UTF-8.

* Modification to allow assignment of an Array with an input name and an optional Hash of values to soap.input.
  Patches [issue #30](https://github.com/savonrb/savon/issues/30) (stanleydrew <andrewmbenton@gmail.com>).

* Fix for [issue #25](https://github.com/savonrb/savon/issues/25).

### 0.7.2 (2010-01-17)

* Exposed the `Net::HTTP` response (added by Kevin Ingolfsland). Use the `http` accessor (`response.http`)
  on your `Savon::Response` to access the `Net::HTTP` response object.

* Fix for [issue #21](https://github.com/savonrb/savon/issues/21).

* Fix for [issue #22](https://github.com/savonrb/savon/issues/22).

* Fix for [issue #19](https://github.com/savonrb/savon/issues/19).

* Added support for global header and namespaces. See [issue #9](https://github.com/savonrb/savon/issues/9).

### 0.7.1 (2010-01-10)

* The Hash of HTTP headers for SOAP calls is now public via `Savon::Request#headers`.
  Patch for [issue #8](https://github.com/savonrb/savon/issues/8).

### 0.7.0 (2010-01-09)

This version comes with several changes to the public API!
Pay attention to the following list and read the updated Wiki: http://wiki.github.com/savonrb/savon

* Changed how `Savon::WSDL` can be disabled. Instead of disabling the WSDL globally/per request via two
  different methods, you now simply append an exclamation mark (!) to your SOAP call: `client.get_all_users!`
  Make sure you know what you're doing because when the WSDL is disabled, Savon does not know about which
  SOAP actions are valid and just dispatches everything.

* The `Net::HTTP` object used by `Savon::Request` to retrieve WSDL documents and execute SOAP calls is now public.
  While this makes the library even more flexible, it also comes with two major changes:

  * SSL client authentication needs to be defined directly on the `Net::HTTP` object:

      ``` ruby
      client.request.http.client_cert = ...
      ```

    I added a shortcut method for setting all options through a Hash similar to the previous implementation:

      ``` ruby
      client.request.http.ssl_client_auth :client_cert => ...
      ```

  * Open and read timeouts also need to be set on the `Net::HTTP` object:

      ``` ruby
      client.request.http.open_timeout = 30
      client.request.http.read_timeout = 30
      ```

  * Please refer to the `Net::HTTP` documentation for more details:
    http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html

* Thanks to JulianMorrison, Savon now supports HTTP basic authentication:

    ``` ruby
    client.request.http.basic_auth "username", "password"
    ```

* Julian also added a way to explicitly specify the order of Hash keys and values, so you should now be able
  to work with services requiring a specific order of input parameters while still using Hash input.

    ``` ruby
    client.find_user { |soap| soap.body = { :name => "Lucy", :id => 666, :@inorder => [:id, :name] } }
    ```

* `Savon::Response#to_hash` now returns the content inside of "soap:Body" instead of trying to go one
  level deeper and return it's content. The previous implementation only worked when the "soap:Body" element
  contained a single child. See [issue #17](https://github.com/savonrb/savon/issues/17).

* Added `Savon::SOAP#namespace` as a shortcut for setting the "xmlns:wsdl" namespace.

    ``` ruby
    soap.namespace = "http://example.com"
    ```

### 0.6.8 (2010-01-01)

* Improved specifications for various kinds of WSDL documents.

* Added support for SOAP endpoints which are different than the WSDL endpoint of a service.

* Changed how SOAP actions and inputs are retrieved from the WSDL documents. This might break a few existing
  implementations, but makes Savon work well with even more services. If this change breaks your implementation,
  please take a look at the `action` and `input` methods of the `Savon::SOAP` object.
  One specific problem I know of is working with the createsend WSDL and its namespaced actions.

    To make it work, call the SOAP action without namespace and specify the input manually:

    ``` ruby
      client.get_api_key { |soap| soap.input = "User.GetApiKey" }
    ```

### 0.6.7 (2009-12-18)

* Implemented support for a proxy server. The proxy URI can be set through an optional Hash of options passed
  to instantiating `Savon::Client` (Dave Woodward <dave@futuremint.com>)

* Implemented support for SSL client authentication. Settings can be set through an optional Hash of arguments
  passed to instantiating `Savon::Client` (colonhyphenp)

* Patch for [issue #10](https://github.com/savonrb/savon/issues/10).

### 0.6.6 (2009-12-14)

* Default to use the name of the SOAP action (the method called in a client) in lowerCamelCase for SOAP action
  and input when Savon::WSDL is disabled. You still need to specify soap.action and maybe soap.input in case
  your SOAP actions are named any different.

### 0.6.5 (2009-12-13)

* Added an `open_timeout` method to `Savon::Request`.

### 0.6.4 (2009-12-13)

* Refactored specs to be less unit-like.

* Added a getter for the `Savon::Request` to `Savon::Client` and a `read_timeout` setter for HTTP requests.

* `wsdl.soap_actions` now returns an Array of SOAP actions. For the previous "mapping" please use `wsdl.operations`.

* Replaced WSDL document with stream parsing.

    ```
      Benchmarks (1000 SOAP calls):

             user        system     total       real
      0.6.4  72.180000   8.280000   80.460000   (750.799011)
      0.6.3  192.900000  19.630000  212.530000  (914.031865)
    ```

### 0.6.3 (2009-12-11)

* Removing 2 ruby deprecation warnings for parenthesized arguments. (Dave Woodward <dave@futuremint.com>)

* Added global and per request options for disabling `Savon::WSDL`.

    ```
    Benchmarks (1000 SOAP calls):

                   user        system     total       real
    WSDL           192.900000  19.630000  212.530000  (914.031865)
    disabled WSDL  5.680000    1.340000   7.020000    (298.265318)
    ```

* Improved XPath expressions for parsing the WSDL document.

    ```
    Benchmarks (1000 SOAP calls):

           user        system     total       real
    0.6.3  192.900000  19.630000  212.530000  (914.031865)
    0.6.2  574.720000  78.380000  653.100000  (1387.778539)
    ```

### 0.6.2 (2009-12-06)

* Added support for changing the name of the SOAP input node.

* Added a CHANGELOG.

### 0.6.1 (2009-12-06)

* Fixed a problem with WSSE credentials, where every request contained a WSSE authentication header.

### 0.6.0 (2009-12-06)

* `method_missing` now yields the SOAP and WSSE objects to a given block.

* The response_process (which previously was a block passed to method_missing) was replaced by `Savon::Response`.

* Improved SOAP action handling (another problem that came up with issue #1).

### 0.5.3 (2009-11-30)

* Patch for [issue #2](https://github.com/savonrb/savon/issues/2).

### 0.5.2 (2009-11-30)

* Patch for [issue #1](https://github.com/savonrb/savon/issues/1).

### 0.5.1 (2009-11-29)

* Optimized default response process.

* Added WSSE settings via defaults.

* Added SOAP fault and HTTP error handling.

* Improved documentation

* Added specs

### 0.5.0 (2009-11-29)

* Complete rewrite and public release.
