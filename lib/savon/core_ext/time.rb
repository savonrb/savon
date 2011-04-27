module Savon
  module CoreExt
    module Time

      # Returns an xs:dateTime formatted String.
      def xs_datetime
        zone = if utc_offset < 0
          "-#{"%02d" % (- utc_offset / 3600)}:#{"%02d" % ((- utc_offset % 3600) / 60)}"
        elsif utc_offset > 0
          "+#{"%02d" % (utc_offset / 3600)}:#{"%02d" % ((utc_offset % 3600) / 60)}"
        else
          "Z"
        end

        strftime "%Y-%m-%dT%H:%M:%S#{zone}"
      end

    end
  end
end

Time.send :include, Savon::CoreExt::Time
