# Savon

Heavy metal SOAP client

[Documentation](http://savonrb.com) | [RDoc](http://rubydoc.info/gems/savon) |
[Mailing list](https://groups.google.com/forum/#!forum/savonrb) | [Twitter](http://twitter.com/savonrb)

[![Build Status](https://secure.travis-ci.org/savonrb/savon.png?branch=master)](http://travis-ci.org/savonrb/savon)
[![Gem Version](https://badge.fury.io/rb/savon.png)](http://badge.fury.io/rb/savon)
[![Code Climate](https://codeclimate.com/github/savonrb/savon.png)](https://codeclimate.com/github/savonrb/savon)
[![Coverage Status](https://coveralls.io/repos/savonrb/savon/badge.png?branch=version2)](https://coveralls.io/r/savonrb/savon)


## Version 2

Savon version 2 is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

```
$ gem install savon
```

or add it to your Gemfile like this:

```
gem 'savon', '~> 2.12.0'
```

## Usage example

``` ruby
require 'savon'

# create a client for the service
client = Savon.client(wsdl: 'http://service.example.com?wsdl')

client.operations
# => [:find_user, :list_users]

# call the 'findUser' operation
response = client.call(:find_user, message: { id: 42 })

response.body
# => { find_user_response: { id: 42, name: 'Hoff' } }
```

For more examples, you should check out the
[integration tests](https://github.com/savonrb/savon/tree/version2/spec/integration).

## FAQ

* URI::InvalidURIError -- if you see this error, then it is likely that the http client you are using cannot parse the URI for your WSDL. Try `gem install httpclient` or add it to your `Gemfile`.
  - See https://github.com/savonrb/savon/issues/488 for more info

## Give back

If you're using Savon and you or your company is making money from it, then please consider
donating via [Gittip](https://www.gittip.com/tjarratt/) so that I can continue to improve it.

[![donate](donate.png)](https://www.gittip.com/tjarratt/)


## Documentation

Please make sure to [read the documentation](http://savonrb.com/version2/).

And if you find any problems with it or if you think something's missing,
feel free to [help out and improve the documentation](https://github.com/savonrb/savonrb.com).

Donate icon from the [Noun Project](http://thenounproject.com/noun/donate/#icon-No285).
