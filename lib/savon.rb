module Savon

  class Error < RuntimeError; end
  class InitializationError < Error; end
  class InvalidResponseError < Error; end

  def self.client(globals = {}, &block)
    Client.new(globals, &block)
  end

  def self.observers
    @observers ||= []
  end

  def self.notify_observers(operation_name, builder, globals, locals)
    observers.inject(nil) do |response, observer|
      observer.notify(operation_name, builder, globals, locals)
    end
  end

end

require "savon/version"
require "savon/client"
require "savon/model"
