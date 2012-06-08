require "bundler"
Bundler.require :default, :development

support_files = File.expand_path("spec/support/**/*.rb")
Dir[support_files].each { |file| require file }

RSpec.configure do |config|
  config.include SpecSupport::Methods
end
