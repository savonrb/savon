require "savon/mock"

module Savon
  module SpecHelper

    def savon
      Savon
    end

    def verify_mocks_for_rspec
      super if defined? super
      savon.verify!
    end

  end
end
