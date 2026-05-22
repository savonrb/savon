# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem "faraday", "~> 2.14"
gem "faraday-digestauth", "~> 0.4"
gem "faraday-follow_redirects", "~> 0.5"
# faraday-ntlm_auth pins Ruby to `>= 3.0, < 4`, so we can't use that on Ruby 4,
# and truffleruby is also failing. ntlm transport specs are skipped.
gem "faraday-ntlm_auth", "~> 0.1" if RUBY_ENGINE == "ruby" && Gem::Version.new(RUBY_VERSION) < Gem::Version.new("4.0")
gem "httpclient", "~> 2.7.1"
gem "webrick"

gem "bundler-audit", "~> 0.9.3", require: false
gem "net-smtp" if RUBY_VERSION >= "3.1.0"
gem "rubocop", "~> 1.86", ">= 1.86.2"
gem "rubocop-rake", "~> 0.7.1"
gem "rubocop-rspec", "~> 3.9"
gem "simplecov", require: false
