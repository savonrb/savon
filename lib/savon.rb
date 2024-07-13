# frozen_string_literal: true
module Savon

  Error                 = Class.new(RuntimeError)
  InitializationError   = Class.new(Error)
  UnknownOptionError    = Class.new(Error)
  UnknownOperationError = Class.new(Error)
  InvalidResponseError  = Class.new(Error)

  class DeprecatedOptionError < Error
    attr_accessor :option
    def initialize(option)
      @option = option
      super("#{option} is deprecated as it is not supported in Faraday. See https://github.com/savonrb/savon/blob/main/UPGRADING.md for more information.")
    end
  end

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
require "savon/string_utils"
