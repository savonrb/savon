require "savon/logger"

module Savon
  class NullLogger < Logger

    def log(*)
    end

  end
end
