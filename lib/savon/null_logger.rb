require "savon/logger"

module Savon
  class NullLogger < Logger

    def log(*)
    end

    def log_filtered(*)
    end

  end
end
