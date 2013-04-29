require "bundler"
Bundler.require :default, :development

unless RUBY_PLATFORM =~ /java/
  require "simplecov"
  require "coveralls"

  SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  SimpleCov.start do
    add_filter "spec"
  end
end

support_files = File.expand_path("spec/support/**/*.rb")
Dir[support_files].each { |file| require file }

RSpec.configure do |config|
  config.include SpecSupport::Methods
end
