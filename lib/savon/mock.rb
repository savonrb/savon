module Savon
  class ExpectationError < Error; end
end

require "savon/mock/interface"
Savon.extend Savon::MockInterface
