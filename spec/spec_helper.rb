require 'bundler'
Bundler.setup(:default, :development)

unless RUBY_PLATFORM =~ /java/
  require 'simplecov'
  require 'coveralls'

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter('spec')
  end
end

require 'savon'

# $ DEBUG=root rspec         # enables all loggers
# $ DEBUG=Savon::Body rspec  # enables a specific logger
if logger_to_enable = ENV['DEBUG']
  logger = Logging.logger[logger_to_enable]
  logger.add_appenders(Logging.appenders.stdout)
  logger.level = :debug
end

require 'rspec'
require 'equivalent-xml'

support_files = File.expand_path('spec/support/**/*.rb')
Dir[support_files].each { |file| require file }

RSpec.configure do |config|
  config.include SpecSupport
  config.mock_with :mocha
  config.order = 'random'
end
