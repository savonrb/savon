## 0.9.5 (2011-07-03)

* Refactoring: Extracted WSSE authentication out into the [akami](http://rubygems.org/gems/akami) gem.

## 0.9.4 (2011-07-03)

* Refactoring: Extracted the WSDL parser out into the [wasabi](http://rubygems.org/gems/wasabi) gem.
  This should isolate upcoming improvements to the parser.

## 0.9.3 (2011-06-30)

* Fix: [issue 138](https://github.com/rubiii/savon/issues/138) -
  Savon now supports setting a global SOAP header via `Savon.soap_header=`.

* Fixed the namespace for wsse message timestamps from `wsse:Timestamp`
  to `wsu:Timestamp` as required by the specification.

* Change: Removed support for NTLM authentication until it's stable. If you need it, you can still
  add the following line to your Gemfile:

      gem "httpi", "0.9.4"

* Refactoring:

  * `Hash#map_soap_response` and some of its helpers are moved to [Nori v1.0.0](http://rubygems.org/gems/nori/versions/1.0.0).
    Along with replacing core extensions with a proper implementation, Nori now contains a number of methods
    for configuring its default behavior:

    * The option whether to strip namespaces was moved to Nori.strip_namespaces
    * You can disable "advanced typecasting" for SOAP response values
    * And you can configure how SOAP response keys should be converted

    Please take a look at [Nori's CHANGELOG](https://github.com/rubiii/nori/blob/master/CHANGELOG.md)
    for detailed information.

  * `Savon::SOAP::XML.to_hash`, `Savon::SOAP::XML.parse` and `Savon::SOAP::XML.to_array` are gone.
    It wasn't worth keeping them around, because they didn't do much. You can simply parse a SOAP
    response and translate it to a Savon SOAP response Hash via:

        Nori.parse(xml)[:envelope][:body]

  * `Savon::SOAP::Response#basic_hash` is now `Savon::SOAP::Response#hash`.

## 0.9.2 (2011-04-30)

* Fix: [issue 154](https://github.com/rubiii/savon/pull/154) -
  Timezone format used by Savon now matches the XML schema spec.

* Improvement: WSSE basic, digest and timestamp authentication are no longer mutually exclusive.
  Thanks to [mleon](https://github.com/mleon) for solving [issue #142](https://github.com/rubiii/savon/issues/142).

* Improvement: Switched from using Crack to translate the SOAP response to a Hash to using
  [Nori](http://rubygems.org/gems/nori). It's based on Crack and comes with pluggable parsers.
  It defaults to REXML, but you can switch to Nokogiri via:

      Nori.parser = :nokogiri

* Improvement: WSDL parsing now uses Nokogiri instead of REXML.

## 0.9.1 (2011-04-06)

* Improvement: if you're only setting the local or remote address of your wsdl document, you can
  now pass an (optional) String to `Savon::Client.new` to set `wsdl.document`.

      Savon::Client.new "http://example.com/UserService?wsdl"

* Improvement: instead of calling the `to_hash` method of your response again and again and again,
  there is now a ' #[]` shortcut for you.

      response[:authenticate_response][:return]

## 0.9.0 (2011-04-05)

* Feature: issues [#158](https://github.com/rubiii/savon/issues/158),
  [#169](https://github.com/rubiii/savon/issues/169) and [#172](https://github.com/rubiii/savon/issues/172)
  configurable "Hash key Symbol to lowerCamelCase" conversion by using the latest version of
  [Gyoku](http://rubygems.org/gems/gyoku).

      Gyoku.convert_symbols_to(:camelcase)
      Gyoku.xml(:first_name => "Mac")  # => "<FirstName></Firstname>"

  You can even define your own conversion formular.

      Gyoku.convert_symbols_to { |key| key.upcase }
      Gyoku.xml(:first_name => "Mac")  # => "<FIRST_NAME></FIRST_NAME>"

  This should also work for the SOAP input tag and SOAPAction header. So if you had to use a String for
  the SOAP action to call because your services uses CamelCase instead of lowerCamelCase, you can now
  change the default and use Symbols instead.

      Gyoku.convert_symbols_to(:camelcase)

      # pre Gyoku 0.4.0
      client.request(:get_user)  # => "<getUser/>"
      client.request("GetUser")  # => "<GetUser/>"

      # post Gyoku 0.4.0
      client.request(:get_user)  # => "<GetUser/>"

* Improvement: issues [#170](https://github.com/rubiii/savon/issues/170) and
  [#173](https://github.com/rubiii/savon/issues/173) Savon no longer rescues exceptions raised by
  `Crack::XML.parse`. If Crack complains about your WSDL document, you should take control and
  solve the problem instead of getting no response.

* Improvement: issue [#172](https://github.com/rubiii/savon/issues/172) support for global env_namespace.

      Savon.configure do |config|
        config.env_namespace = :soapenv  # changes the default :env namespace
      end

* Fix: [issue #163](https://github.com/rubiii/savon/issues/163) "Savon 0.8.6 not playing nicely
  with Httpi 0.9.0". Updating HTTPI to v0.9.1 should solve this problem.

* And if you haven't already seen the new documentation: [savonrb.com](http://savonrb.com)

## 0.8.6 (2011-02-15)

* Fix for issues [issue #147](https://github.com/rubiii/savon/issues/147) and [#151](https://github.com/rubiii/savon/issues/151)
  ([771194](https://github.com/rubiii/savon/commit/771194)).

## 0.8.5 (2011-01-28)

* Fix for [issue #146](https://github.com/rubiii/savon/issues/146) ([98655c](https://github.com/rubiii/savon/commit/98655c)).

* Fix for [issue #147](https://github.com/rubiii/savon/issues/147) ([252670](https://github.com/rubiii/savon/commit/252670)).

## 0.8.4 (2011-01-26)

* Fix for issues [issue #130](https://github.com/rubiii/savon/issues/130) and [#134](https://github.com/rubiii/savon/issues/134)
  ([4f9847](https://github.com/rubiii/savon/commit/4f9847)).

* Fix for [issue #91](https://github.com/rubiii/savon/issues/91) ([5c8ec1](https://github.com/rubiii/savon/commit/5c8ec1)).

* Fix for [issue #135](https://github.com/rubiii/savon/issues/135) ([c9261d](https://github.com/rubiii/savon/commit/c9261d)).

## 0.8.3 (2011-01-11)

* Moved implementation of `Savon::SOAP::Response#to_array` to a class method at `Savon::SOAP::XML.to_array`
  ([05a7d3](https://github.com/rubiii/savon/commit/05a7d3)).

* Fix for [issue #131](https://github.com/rubiii/savon/issues/131) ([4e57b3](https://github.com/rubiii/savon/commit/4e57b3)).

## 0.8.2 (2011-01-04)

* Fix for [issue #127](https://github.com/rubiii/savon/issues/127) ([0eb3da](https://github.com/rubiii/savon/commit/0eb3da4)).

* Changed `Savon::WSSE` to be based on a Hash instead of relying on builder ([4cebc3](https://github.com/rubiii/savon/commit/4cebc3)).

  `Savon::WSSE` now supports wsse:Timestamp headers ([issue #122](https://github.com/rubiii/savon/issues/122)) by setting
  `Savon::WSSE#timestamp` to `true`:

      client.request :some_method do
        wsse.timestamp = true
      end

   or by setting `Savon::WSSE#created_at` or `Savon::WSSE#expires_at`:

      client.request :some_method do
        wsse.created_at = Time.now
        wsse.expires_at = Time.now + 60
      end

  You can also add custom tags to the WSSE header ([issue #69](https://github.com/rubiii/savon/issues/69)):

      client.request :some_method do
        wsse["wsse:Security"]["wsse:UsernameToken"] = { "Organization" => "ACME", "Domain" => "acme.com" }
      end

## 0.8.1 (2010-12-22)

* Update to depend on HTTPI v0.7.5 which comes with a fallback to use Net::HTTP when no other adapter could be required.

* Fix for [issue #72](https://github.com/rubiii/savon/issues/72) ([22074a](https://github.com/rubiii/savon/commit/22074a8)).

* Loosen dependency on builder. Should be quite stable.

## 0.8.0 (2010-12-20)

* Added `Savon::SOAP::XML#env_namespace` ([51fa0e](https://github.com/rubiii/savon/commit/51fa0e)) to configure
  the SOAP envelope namespace. It defaults to :env but can also be set to an empty String for SOAP envelope
  tags without a namespace.

* Replaced quite a lot of core extensions by moving the Hash to XML translation into a new gem called
  [Gyoku](http://rubygems.org/gems/gyoku) ([bac4b4](https://github.com/rubiii/savon/commit/bac4b4)).

## 0.8.0.beta.4 (2010-11-20)

* Fix for [issue #107](https://github.com/rubiii/savon/issues/107) ([1d6eda](https://github.com/rubiii/savon/commit/1d6eda)).

* Fix for [issue #108](https://github.com/rubiii/savon/issues/108)
  ([f64400...0aaca2](https://github.com/rubiii/savon/compare/f64400...0aaca2)) Thanks [fagiani](https://github.com/fagiani).

* Replaced `Savon.response_pattern` with a slightly different implementation of the `Savon::SOAP::Response#to_array` method
  ([6df6a6](https://github.com/rubiii/savon/commit/6df6a6)). The method now accepts multiple arguments representing the response
  Hash keys to traverse and returns the result as an Array or an empty Array in case the key is nil or does not exist.

      response.to_array :get_user_response, :return
      # => [{ :id => 1, :name => "foo"}, { :id => 2, :name => "bar"}]

## 0.8.0.beta.3 (2010-11-06)

* Fix for [savon_spec](http://rubygems.org/gems/savon_spec) to not send nil to `Savon::SOAP::XML#body`
  ([c34b42](https://github.com/rubiii/savon/commit/c34b42)).

## 0.8.0.beta.2 (2010-11-05)

* Added `Savon.response_pattern` ([0a12fb](https://github.com/rubiii/savon/commit/0a12fb)) to automatically walk deeper into
  the SOAP response Hash when a pattern (specified as an Array of Regexps and Symbols) matches the response. If for example
  your response always looks like ".+Response/return" as in:

      <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
        <soap:Body>
          <ns2:authenticateResponse xmlns:ns2="http://v1_0.ws.user.example.com">
            <return>
              <some>thing</some>
            </return>
          </ns2:authenticateResponse>
        </soap:Body>
      </soap:Envelope>

  you could set the response pattern to:

      Savon.configure do |config|
        config.response_pattern = [/.+_response/, :return]
      end

  then instead of calling:

      response.to_hash[:authenticate_response][:return]  # :some => "thing"

  to get the actual content, Savon::SOAP::Response#to_hash will try to apply given the pattern:

      response.to_hash  # :some => "thing"

  Please notice, that if you don't specify a response pattern or if the pattern doesn't match the
  response, Savon will behave like it always did.

* Added `Savon::SOAP::Response#to_array` (which also uses the response pattern).

## 0.8.0.beta.1 (2010-10-29)

* Changed `Savon::Client.new` to accept a block instead of multiple Hash arguments. You can access the
  wsdl, http and wsse objects inside the block to configure your client for a particular service.

			# Instantiating a client to work with a WSDL document
      client = Savon::Client.new do
        wsdl.document = "http://example.com?wsdl"
      end

			# Directly accessing the SOAP endpoint
			client = Savon::Client.new do
        wsdl.endpoint = "http://example.com"
        wsdl.namespace = "http://v1.example.com"
      end

* Fix for [issue #77](https://github.com/rubiii/savon/issues/77), which means you can now use
  local WSDL documents:

      client = Savon::Client.new do
        wsdl.document = "../wsdl/service.xml"
      end

* Changed the way SOAP requests are being dispatched. Instead of using method_missing, you now use
  the new `request` method, which also accepts a block for you to access the wsdl, http, wsse and
  soap object. Please notice, that a new soap object is created for every request. So you can only
  access it inside this block.

      # A simple request to an :authenticate method
      client.request :authenticate do
        soap.body = { :id => 1 }
      end

* The new `Savon::Client#request` method fixes issues [#37](https://github.com/rubiii/savon/issues/37),
  [#61](https://github.com/rubiii/savon/issues/61) and [#64](https://github.com/rubiii/savon/issues/64),
  which report problems with namespacing the SOAP input tag and attaching attributes to it.
  Some usage examples:

      client.request :get_user                  # Input tag: <getUser>
      client.request :wsdl, "GetUser"           # Input tag: <wsdl:GetUser>
      client.request :get_user :active => true  # Input tag: <getUser active="true">

* Savon's new `request` method respects the given namespace. If you don't give it a namespace,
  Savon will set the target namespace to "xmlns:wsdl". But if you do specify a namespace, it will
  be set to the given Symbol.

* Refactored Savon to use the new [HTTPI](http://rubygems.org/gems/httpi) gem.
  `HTTPI::Request` replaces the `Savon::Request`, so please make sure to have a look
  at the HTTPI library and let me know about any problems. Using HTTPI actually
  fixes the following two issues.

* Savon now adds both "xmlns:xsd" and "xmlns:xsi" namespaces for you. Thanks Averell.
  It also properly serializes nil values as xsi:nil = "true".

* Fix for [issue #24](https://github.com/rubiii/savon/issues/24).
  Instead of Net/HTTP, Savon now uses HTTPI to execute HTTP requests.
  HTTPI defaults to use HTTPClient which supports HTTP digest authentication.

* Fix for [issue #76](https://github.com/rubiii/savon/issues/76).
  You now have to explicitly specify whether to use a WSDL document, when instantiating a client.

* Fix for [issue #75](https://github.com/rubiii/savon/issues/75).
  Both `Savon::SOAP::Fault` and `Savon::HTTP::Error` now contain the `HTTPI::Response`.
  They also inherit from `Savon::Error`, making it easier to rescue both at the same time.

* Fix for [issue #87](https://github.com/rubiii/savon/issues/87).
  Thanks to Leonardo Borges.

* Fix for [issue #81](https://github.com/rubiii/savon/issues/81).
  Replaced `Savon::WSDL::Document#to_s` with a `to_xml` method.

* Fix for issues [#85](https://github.com/rubiii/savon/issues/85) and [#88](https://github.com/rubiii/savon/issues/88).

* Fix for [issue #80](https://github.com/rubiii/savon/issues/80).

* Fix for [issue #60](https://github.com/rubiii/savon/issues/60).

* Fix for [issue #96](https://github.com/rubiii/savon/issues/96).

* Removed global WSSE credentials. Authentication needs to be set up for each client instance.

* Started to remove quite a few core extensions.

## 0.7.9 (2010-06-14)

* Fix for [issue #53](https://github.com/rubiii/savon/issues/53).

## 0.7.8 (2010-05-09)

* Fixed gemspec to include missing files in the gem.

## 0.7.7 (2010-05-09)

* SOAP requests now start with a proper XML declaration.

* Added support for gzipped requests and responses (http://github.com/lucascs). While gzipped SOAP
  responses are decoded automatically, you have to manually instruct Savon to gzip SOAP requests:

      client = Savon::Client.new "http://example.com/UserService?wsdl", :gzip => true

* Fix for [issue #51](https://github.com/rubiii/savon/issues/51). Added the :soap_endpoint option to
  `Savon::Client.new` which lets you specify a SOAP endpoint per client instance:

      client = Savon::Client.new "http://example.com/UserService?wsdl",
        :soap_endpoint => "http://localhost/UserService"

* Fix for [issue #50](https://github.com/rubiii/savon/issues/50). Savon still escapes special characters
  in SOAP request Hash values, but you can now append an exclamation mark to Hash keys specifying that
  it's value should not be escaped.

## 0.7.6 (2010-03-21)

* Moved documentation from the Github Wiki to the actual class files and established a much nicer
  documentation combining examples and implementation (using Hanna) at: http://savon.rubiii.com

* Added `Savon::Client#call` as a workaround for dispatching calls to SOAP actions named after
  existing methods. Fix for [issue #48](https://github.com/rubiii/savon/issues/48).

* Add support for specifying attributes for duplicate tags (via Hash values as Arrays).
  Fix for [issue #45](https://github.com/rubiii/savon/issues/45).

* Fix for [issue #41](https://github.com/rubiii/savon/issues/41).

* Fix for issues [#39](https://github.com/rubiii/savon/issues/39) and [#49](https://github.com/rubiii/savon/issues/49).
  Added `Savon::SOAP#xml` which let's you specify completely custom SOAP request XML.

## 0.7.5 (2010-02-19)

* Fix for [issue #34](https://github.com/rubiii/savon/issues/34).

* Fix for [issue #36](https://github.com/rubiii/savon/issues/36).

* Added feature requested in [issue #35](https://github.com/rubiii/savon/issues/35).

* Changed the key for specifying the order of tags from :@inorder to :order!

## 0.7.4 (2010-02-02)

* Fix for [issue #33](https://github.com/rubiii/savon/issues/33).

## 0.7.3 (2010-01-31)

* Added support for Geotrust-style WSDL documents (Julian Kornberger <github.corny@digineo.de>).

* Make HTTP requests include path and query only. This was breaking requests via proxy as scheme and host
  were repeated (Adrian Mugnolo <adrian@mugnolo.com>)

* Avoid warning on 1.8.7 and 1.9.1 (Adrian Mugnolo <adrian@mugnolo.com>).

* Fix for [issue #29](https://github.com/rubiii/savon/issues/29).
  Default to UTC to xs:dateTime value for WSSE authentication.

* Fix for [issue #28](https://github.com/rubiii/savon/issues/28).

* Fix for [issue #27](https://github.com/rubiii/savon/issues/27). The Content-Type now defaults to UTF-8.

* Modification to allow assignment of an Array with an input name and an optional Hash of values to soap.input.
  Patches [issue #30](https://github.com/rubiii/savon/issues/30) (stanleydrew <andrewmbenton@gmail.com>).

* Fix for [issue #25](https://github.com/rubiii/savon/issues/25).

## 0.7.2 (2010-01-17)

* Exposed the `Net::HTTP` response (added by Kevin Ingolfsland). Use the `http` accessor (`response.http`)
  on your `Savon::Response` to access the `Net::HTTP` response object.

* Fix for [issue #21](https://github.com/rubiii/savon/issues/21).

* Fix for [issue #22](https://github.com/rubiii/savon/issues/22).

* Fix for [issue #19](https://github.com/rubiii/savon/issues/19).

* Added support for global header and namespaces. See [issue #9](https://github.com/rubiii/savon/issues/9).

## 0.7.1 (2010-01-10)

* The Hash of HTTP headers for SOAP calls is now public via `Savon::Request#headers`.
  Patch for [issue #8](https://github.com/rubiii/savon/issues/8).

## 0.7.0 (2010-01-09)

This version comes with several changes to the public API!
Pay attention to the following list and read the updated Wiki: http://wiki.github.com/rubiii/savon

* Changed how `Savon::WSDL` can be disabled. Instead of disabling the WSDL globally/per request via two
  different methods, you now simply append an exclamation mark (!) to your SOAP call: `client.get_all_users!`
  Make sure you know what you're doing because when the WSDL is disabled, Savon does not know about which
  SOAP actions are valid and just dispatches everything.

* The `Net::HTTP` object used by `Savon::Request` to retrieve WSDL documents and execute SOAP calls is now public.
  While this makes the library even more flexible, it also comes with two major changes:

  * SSL client authentication needs to be defined directly on the `Net::HTTP` object:

      client.request.http.client_cert = ...

    I added a shortcut method for setting all options through a Hash similar to the previous implementation:

      client.request.http.ssl_client_auth :client_cert => ...

  * Open and read timeouts also need to be set on the `Net::HTTP` object:
  
      client.request.http.open_timeout = 30
      client.request.http.read_timeout = 30

  * Please refer to the `Net::HTTP` documentation for more details:
    http://www.ruby-doc.org/stdlib/libdoc/net/http/rdoc/index.html

* Thanks to JulianMorrison, Savon now supports HTTP basic authentication:

    client.request.http.basic_auth "username", "password"

* Julian also added a way to explicitly specify the order of Hash keys and values, so you should now be able
  to work with services requiring a specific order of input parameters while still using Hash input.

      client.find_user { |soap| soap.body = { :name => "Lucy", :id => 666, :@inorder => [:id, :name] } }

* `Savon::Response#to_hash` now returns the content inside of "soap:Body" instead of trying to go one
  level deeper and return it's content. The previous implementation only worked when the "soap:Body" element
  contained a single child. See [issue #17](https://github.com/rubiii/savon/issues/17).

* Added `Savon::SOAP#namespace` as a shortcut for setting the "xmlns:wsdl" namespace.

    soap.namespace = "http://example.com"

## 0.6.8 (2010-01-01)

* Improved specifications for various kinds of WSDL documents.

* Added support for SOAP endpoints which are different than the WSDL endpoint of a service.

* Changed how SOAP actions and inputs are retrieved from the WSDL documents. This might break a few existing
  implementations, but makes Savon work well with even more services. If this change breaks your implementation,
  please take a look at the `action` and `input` methods of the `Savon::SOAP` object.
  One specific problem I know of is working with the createsend WSDL and its namespaced actions.

  To make it work, call the SOAP action without namespace and specify the input manually:

      client.get_api_key { |soap| soap.input = "User.GetApiKey" }

## 0.6.7 (2009-12-18)

* Implemented support for a proxy server. The proxy URI can be set through an optional Hash of options passed
  to instantiating `Savon::Client` (Dave Woodward <dave@futuremint.com>)

* Implemented support for SSL client authentication. Settings can be set through an optional Hash of arguments
  passed to instantiating `Savon::Client` (colonhyphenp)

* Patch for [issue #10](https://github.com/rubiii/savon/issues/10).

## 0.6.6 (2009-12-14)

* Default to use the name of the SOAP action (the method called in a client) in lowerCamelCase for SOAP action
  and input when Savon::WSDL is disabled. You still need to specify soap.action and maybe soap.input in case
  your SOAP actions are named any different.

## 0.6.5 (2009-12-13)

* Added an `open_timeout` method to `Savon::Request`.

## 0.6.4 (2009-12-13)

* Refactored specs to be less unit-like.

* Added a getter for the `Savon::Request` to `Savon::Client` and a `read_timeout` setter for HTTP requests.

* `wsdl.soap_actions` now returns an Array of SOAP actions. For the previous "mapping" please use `wsdl.operations`.

* Replaced WSDL document with stream parsing.

    Benchmarks (1000 SOAP calls):
    
           user        system     total       real
    0.6.4  72.180000   8.280000   80.460000   (750.799011)
    0.6.3  192.900000  19.630000  212.530000  (914.031865)

## 0.6.3 (2009-12-11)

* Removing 2 ruby deprecation warnings for parenthesized arguments. (Dave Woodward <dave@futuremint.com>)

* Added global and per request options for disabling `Savon::WSDL`.

    Benchmarks (1000 SOAP calls):
    
                   user        system     total       real
    WSDL           192.900000  19.630000  212.530000  (914.031865)
    disabled WSDL  5.680000    1.340000   7.020000    (298.265318)

* Improved XPath expressions for parsing the WSDL document.

    Benchmarks (1000 SOAP calls):
    
           user        system     total       real
    0.6.3  192.900000  19.630000  212.530000  (914.031865)
    0.6.2  574.720000  78.380000  653.100000  (1387.778539)

## 0.6.2 (2009-12-06)

* Added support for changing the name of the SOAP input node.

* Added a CHANGELOG.

## 0.6.1 (2009-12-06)

* Fixed a problem with WSSE credentials, where every request contained a WSSE authentication header.

## 0.6.0 (2009-12-06)

* `method_missing` now yields the SOAP and WSSE objects to a given block.

* The response_process (which previously was a block passed to method_missing) was replaced by `Savon::Response`.

* Improved SOAP action handling (another problem that came up with issue #1).

## 0.5.3 (2009-11-30)

* Patch for [issue #2](https://github.com/rubiii/savon/issues/2).

## 0.5.2 (2009-11-30)

* Patch for [issue #1](https://github.com/rubiii/savon/issues/1).

## 0.5.1 (2009-11-29)

* Optimized default response process.

* Added WSSE settings via defaults.

* Added SOAP fault and HTTP error handling.

* Improved documentation

* Added specs

## 0.5.0 (2009-11-29)

* Complete rewrite and public release.
