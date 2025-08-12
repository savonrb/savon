# Upgrading from v2.x to v3.x

Savon 3 replaces its HTTP transport client, [HTTPI](https://github.com/savonrb/httpi) with [Faraday](https://lostisland.github.io/faraday), introducing major breaking changes.

While this brings significant new features and improvements, it also removes or changes some existing features and options.

## Removed Options

### ssl_cert_key_file, ssl_cert_key_password, ssl_cert_file, ssl_ca_cert

These options are no longer supported, as Faraday does not directly support them, and attempting to use them will raise an error.

Resolution: 

For `ssl_cert_key_file` and `ssl_cert_key_password` open and decrypt the client key using OpenSSL, and provide the `OpenSSL::PKey::RSA, OpenSSL::PKey::DSA` as the `ssl_cert_key` option instead.

For `ssl_cert_file` pass the `OpenSSL::X509::Certificate` as the `ssl_cert` option instead.

For `ssl_ca_cert` pass the file as the `ssl_ca_cert_file` option instead.

For more information please see https://lostisland.github.io/faraday/#/customization/ssl-options

### digest_auth

Digest authentication is no longer natively supported. If you need to use it, consider [Faraday::DigestAuth](https://github.com/bhaberer/faraday-digestauth)

## Changed options

### cookies

The `cookies` option now distinguishes between empty and nil string values. If you want to send an empty cookie, you must now set it to an empty string, rather than nil. Nil is reserved for cookie flags like `HttpOnly` or `Secure`. For example:

```ruby
cookies({accept: 'application/json', 'some-cookie': 'foo', "empty-cookie": "", HttpOnly: nil})
```

will send the following cookies:

```
"accept=application/json; some-cookie=foo; empty-cookie=; HttpOnly"
```

### ssl_verify_mode

The `ssl_verify_mode` option now expects an [OpenSSL::SSL::](https://ruby-doc.org/3.2.2/exts/openssl/OpenSSL/SSL.html) constant. Previously, HTTPI would allow the passing of a symbol like `:none` or `:peer`.

```ruby
ssl_verify_mode: :none
```

should now be written as:

```ruby
ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE
```

### adapters
Savon's adapters option now forwards adapter names and options to faraday.  
While not fully supported or tested, it can be used to specify a custom adapter to use.  Must be
compliant with faraday's adapter api.

https://lostisland.github.io/faraday/#/adapters/index

For example
```ruby
client = Savon.client(
  wsdl: "http://example.com?wsdl",
  adapter: [:typhoeus, {connect_timeout: 10}]
)
```
Would create a savon client using the typhoeus adapter with a connect_timeout of 10 seconds.
