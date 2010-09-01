module Savon
  module CoreExt
    module URI
      module Generic

        # Returns whether the URI hints to SSL.
        def ssl?
          !@scheme ? nil : @scheme.starts_with?("https")
        end

      end
    end
  end
end

URI::Generic.send :include, Savon::CoreExt::URI::Generic
