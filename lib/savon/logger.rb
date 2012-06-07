require "logger"
require "nokogiri"
require "savon/log_message"

module Savon
  class Logger

    def initialize(device = $stdout)
      self.device = device
    end

    attr_accessor :device

    def log(message, options = {})
      log_raw LogMessage.new(message, filter, options).to_s
    end

    attr_writer :subject, :level, :filter

    def subject
      @subject ||= ::Logger.new(device)
    end

    def level
      @level ||= :debug
    end

    def filter
      @filter ||= []
    end

    private

    def log_raw(message)
      subject.send(level, message)
    end

  end
end
