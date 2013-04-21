## 3.1.0 (2013-04-21)

* Feature: [#22](https://github.com/savonrb/wasabi/issues/22) added `Wasabi::Document#service_name`
  to return the name of the SOAP service. Original issue: [savonrb/savon#408](https://github.com/savonrb/savon/pull/408).

* Fix: [#21](https://github.com/savonrb/wasabi/issues/21) when the Resolver gets an
  erroneous response (such as a 404), we now raise a more useful HTTPError.

* Fix: [#23](https://github.com/savonrb/wasabi/issues/23) ignore extension base elements
  defined in imports.

## 3.0.0 (2012-12-17)

* Updated to HTTPI 2.0 to play nicely with Savon 2.0.

## 2.5.1 (2012-08-22)

* Fix: [#14](https://github.com/rubiii/wasabi/issues/14) fixes an issue where
  finding the correct SOAP input tag and namespace identifier fails when portTypes
  are imported, since imports are currently not supported.

  The bug was introduced in v2.2.0 by [583cf6](https://github.com/rubiii/wasabi/commit/583cf658f1953411a7a7a4c22923fa0a046c8d6d)

* Refactoring: Removed `Object#blank?` core extension.

## 2.5.0 (2012-06-28)

* Fix: [#10](https://github.com/rubiii/wasabi/issues/10) fixes an issue where
  Wasabi used the wrong operation name.

## 2.4.1 (2012-06-18)

* Fix: [rubiii/savon#296](https://github.com/rubiii/savon/issues/296) fixes an issue where
  the WSDL message element doesn't have part element.

## 2.4.0 (2012-06-08)

* Feature: `Wasabi::Document` now accepts either a URL of a remote document,
  a path to a local file or raw XML. The code for this was moved from Savon over
  here as a first step towards supporting WSDL imports.

## 2.3.0 (2012-06-07)

* Improvement: [#3](https://github.com/rubiii/wasabi/pull/3) adds object inheritance.

## 2.2.0 (2012-06-06)

* Improvement: [#5](https://github.com/rubiii/wasabi/pull/5) - Get input from message
  element or portType input. See [rubiii/savon#277](https://github.com/rubiii/savon/pull/277)
  to get the full picture on how this all works together, and enables you to pass a single
  symbol into the `Savon::Client#request` method and get automatic namespace mapping, as well
  as the proper operation name -> input message mapping.

## 2.1.1 (2012-05-18)

* Fix: [issue 7](https://github.com/rubiii/wasabi/issues/7) - Performance regression.

## 2.1.0 (2012-02-17)

* Improvement: The value of elementFormDefault can now be manually specified/overwritten.

* Improvement: [issue 2](https://github.com/rubiii/wasabi/issues/2) - Allow symbolic endpoints
  like "http://server:port".

## 2.0.0 (2011-07-07)

* Feature: Wasabi can now parse type definitions and namespaces.
  Thanks to [jkingdon](https://github.com/jkingdon) for implementing this.

## 1.0.0 (2011-07-03)

* Initial version extracted from the [Savon](http://rubygems.org/gems/savon) library.
  Use it to build your own SOAP client and help to improve it!
