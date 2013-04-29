# Wasabi

A simple WSDL parser.

[![Build Status](https://secure.travis-ci.org/savonrb/wasabi.png)](http://travis-ci.org/savonrb/wasabi)
[![Gem Version](https://badge.fury.io/rb/wasabi.png)](http://badge.fury.io/rb/wasabi)
[![Code Climate](https://codeclimate.com/github/savonrb/wasabi.png)](https://codeclimate.com/github/savonrb/wasabi)
[![Coverage Status](https://coveralls.io/repos/savonrb/wasabi/badge.png?branch=master)](https://coveralls.io/r/savonrb/wasabi)


## Installation

Wasabi is available through [Rubygems](http://rubygems.org/gems/wasabi) and can be installed via:

```
$ gem install wasabi
```


## Getting started

``` ruby
document = Wasabi.document File.read("some.wsdl")
```

Get the SOAP endpoint:

``` ruby
document.endpoint
# => "http://soap.example.com"
```

Get the target namespace:

``` ruby
document.namespace
# => "http://v1.example.com"
```

Check whether elementFormDefault is set to `:qualified` or `:unqualified`:

``` ruby
document.element_form_default
# => :qualified
```

Get a list of available SOAP actions (snakecase for convenience):

``` ruby
document.soap_actions
# => [:create_user, :find_user]
```

Get a map of SOAP action Symbols, their input tag and original SOAP action name:

``` ruby
document.operations
# => { :create_user => { :input => "createUser", :action => "createUser" },
# =>   :find_user => { :input => "findUser", :action => "findUser" } }
```
