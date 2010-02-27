module Savon

  # = Savon::Logger
  #
  # Savon::Logger can be mixed into classes to provide logging behavior.
  #
  # By default, the Logger mixin uses {Ruby's Logger}[http://ruby-doc.org/stdlib/libdoc/logger/rdoc/]
  # from the standard library, a log level of :debug and is pointing to STDOUT.
  module Logger

    module ClassMethods

      # Sets whether to log.
      def log=(log)
        @log = log
      end

      # Returns whether to log. Defaults to +true+.
      def log?
        @log != false
      end

      # Sets the logger.
      def logger=(logger)
        @logger = logger
      end

      # Returns the logger. Defaults to an instance of +Logger+ writing to STDOUT.
      def logger
        @logger ||= ::Logger.new STDOUT
      end

      # Sets the log level.
      def log_level=(log_level)
        @log_level = log_level
      end

      # Returns the log level. Defaults to +debug+.
      def log_level
        @log_level ||= :debug
      end

    end

    # Extends the class including this module with its ClassMethods.
    def self.included(base)
      base.extend ClassMethods
    end

    # Logs a given +message+.
    def log(message)
      self.class.logger.send self.class.log_level, message if self.class.log?
    end

  end
end
