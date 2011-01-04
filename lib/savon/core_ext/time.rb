module Savon
  module CoreExt
    module Time

      # Returns an xs:dateTime formatted String.
      def xs_datetime
        strftime "%Y-%m-%dT%H:%M:%S%Z"
      end

    end
  end
end

Time.send :include, Savon::CoreExt::Time
