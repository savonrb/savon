# Savon

Heavy metal SOAP client

[![Ruby](https://github.com/savonrb/savon/actions/workflows/ci.yml/badge.svg)](https://github.com/savonrb/savon/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/savon.svg)](http://badge.fury.io/rb/savon)
[![Coverage Status](https://coveralls.io/repos/savonrb/savon/badge.svg)](https://coveralls.io/r/savonrb/savon)

Savon is a SOAP client for Ruby. [SOAP is the protocol](https://www.w3.org/TR/soap/) spoken by many enterprise systems in banking, government, ERP or payroll. When they hand you a WSDL URL or file instead of a REST spec, it's SOAP. Savon reads the WSDL, maps available operations to Ruby symbols, converts Ruby hashes to SOAP envelopes and turns XML responses into hashes you can work with.

Full documentation is at [savonrb.com](https://savonrb.com).

## Installation

```ruby
gem 'savon', '~> 2.17'
```

## Usage

```ruby
require 'savon'

# Point Savon to a local or remote WSDL document
client = Savon.client(wsdl: 'https://service.example.com?wsdl')

# See what the service exposes
client.operations
# => [:find_user, :create_user]

# Make a request and work with the response
response = client.call(:find_user, message: { id: 42 })
response.body[:find_user_response]
# => { id: 42, name: "Hoff" }

# Savon raises a Savon::SOAPFault when the server returns a SOAP fault
rescue Savon::SOAPFault => e
  puts e.to_hash.dig(:fault, :faultstring)
```

Enable logging to see the raw SOAP envelopes. That's probably the single most useful thing while getting a new integration working:

```ruby
client = Savon.client(
  wsdl: 'https://service.example.com?wsdl',
  pretty_print_xml: true,
  log: true
)
```

### Authentication

Most enterprise services require authentication. Common options:

```ruby
# HTTP basic auth
Savon.client(wsdl: '...', basic_auth: ['user', 'secret'])

# WS-Security (WSSE)
Savon.client(wsdl: '...', wsse_auth: ['user', 'secret', :digest], wsse_timestamp: true)
```

See [Authentication](https://savonrb.com/version2/globals.html) on the website for HTTP digest, NTLM, and certificate-based options.

### Transport

Savon uses [HTTPI](https://github.com/savonrb/httpi) for HTTP by default. Since v2.17.0 you can opt-in to use Faraday by passing `transport: :faraday` which exposes the Faraday connection at `client.faraday` for you to configure. Savon is only adding some SOAP-specifics on top.

## Ruby support

Savon 2.x requires Ruby 3.0 or later. See the [changelog](CHANGELOG.md) for historical compatibility.

## Known limitations

**WSDL imports are not followed.** Savon parses only the root WSDL document via [Wasabi](https://github.com/savonrb/wasabi). Messages, port types, and bindings defined in imported files are invisible to Savon. If you control the WSDL, merge the imported elements into the root document and pass that to Savon as a string. If you need full import support, the [WSDL](https://rubygems.org/gems/wsdl) gem is an alternative.

**MTOM/XOP support is request framing only.** Savon can emit outbound MTOM/XOP request framing, but it does not rewrite normal base64 XML into XOP, generate `xop:Include` nodes, validate references, infer MIME types from XML, or deserialize inbound MTOM responses. Callers provide the `xop:Include` XML and matching attachment Content-IDs.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). MIT licensed.
