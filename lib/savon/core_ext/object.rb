module Savon
  module CoreExt
    module Object

      # Returns +true+ if the Object is nil, false or empty. Implementation from ActiveSupport.
      def blank?
        respond_to?(:empty?) ? empty? : !self
      end unless method_defined?(:blank?)

    end
  end
end

Object.send :include, Savon::CoreExt::Object
