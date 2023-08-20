# Savon

Heavy metal SOAP client

[Documentation](https://www.rubydoc.info/gems/savon/) | [Support](https://stackoverflow.com/questions/tagged/savon) |
[Mailing list](https://groups.google.com/forum/#!forum/savonrb) | [Twitter](http://twitter.com/savonrb)

[![Ruby](https://github.com/savonrb/savon/actions/workflows/ci.yml/badge.svg)](https://github.com/savonrb/savon/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/savon.svg)](http://badge.fury.io/rb/savon)
[![Code Climate](https://codeclimate.com/github/savonrb/savon.svg)](https://codeclimate.com/github/savonrb/savon)
[![Coverage Status](https://coveralls.io/repos/savonrb/savon/badge.svg)](https://coveralls.io/r/savonrb/savon)


## Version 2

Savon version 2 is available through [Rubygems](http://rubygems.org/gems/savon) and can be installed via:

```
$ gem install savon
```

or add it to your Gemfile like this:

```
gem 'savon', '~> 2.13.0'
```

## Usage example

``` ruby
require 'savon'

# create a client for the service
client = Savon.client(wsdl: 'http://service.example.com?wsdl')

# or: create a client with a wsdl provided as a string
client = Savon.client do |config|
  wsdl_content = File.read("/path/to/wsdl")
  config.wsdl wsdl_content
end

client.operations
# => [:find_user, :list_users]

# call the 'findUser' operation
response = client.call(:find_user, message: { id: 42 })

response.body
# => { find_user_response: { id: 42, name: 'Hoff' } }
```

For more examples, you should check out the
[integration tests](https://github.com/savonrb/savon/tree/version2/spec/integration).

## Ruby version support

* `master` - MRI 2.7, 3.0, 3.1 (same support as Ruby)
* 2.12.x - MRI 2.2, 2.3, 2.4, 2.5
* 2.11.x - MRI 2.0, 2.1, 2.2, and 2.3

If you are running MRI 1.8.7, try a 2.6.x release.

## Running tests

```bash
$ bundle install
$ bundle exec rspec
```

## FAQ

* URI::InvalidURIError -- if you see this error, then it is likely that the http client you are using cannot parse the URI for your WSDL. Try `gem install httpclient` or add it to your `Gemfile`.
  - See https://github.com/savonrb/savon/issues/488 for more info


## Documentation

Please be sure to [read the documentation](https://www.rubydoc.info/github/savonrb/savon/).
