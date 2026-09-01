# frozen_string_literal: true

module Savon
  # The preview channel for the next major version's defaults.
  #
  # Enabled by the +future: true+ global option, read by
  # {Savon::GlobalOptions#future}. Everything the preview changes arrives
  # as a default. An option you set explicitly wins over a previewed
  # default the same way it wins over a built-in one. There is no finer
  # control than that. Previewed behavior changes cannot be switched off
  # individually. The preview grows with 2.x minor releases, and each
  # release lists its additions under the "3.0 preview" section of the
  # changelog. Version 3.0 makes the previewed behavior the default and
  # the flag a no-op.
  #
  # The preview covers option defaults ({GLOBAL_DEFAULTS} and
  # {NORI_PROFILES}) as well as behavior changes such as {Savon::Client}
  # freezing its options once the client is created.
  module Future
    # Global options the flag overlays between the built-in defaults and
    # the caller's explicit options.
    GLOBAL_DEFAULTS = {
      transport: :faraday
    }.freeze

    # Nori profiles Savon enables for response parsing under the flag.
    # {Savon::Response} passes them when building its Nori instance.
    NORI_PROFILES = {
      standards: true,
      serializable: true
    }.freeze

    # Where the preview channel is announced and release updates are posted.
    DISCUSSION_URL = "https://github.com/savonrb/savon/discussions/1060"

    # Logs the preview contract once at client initialization.
    #
    # The line is info-level. A +log_level+ of +:warn+ or higher, or a
    # custom logger, silences it.
    #
    # @param logger [Logger] the logger of the client being initialized
    # @return [void]
    def self.announce(logger)
      logger.info "Savon future: true is on. This client previews the Savon 3.0 defaults. " \
                  "The preview grows with 2.x minor releases. See the '3.0 preview' " \
                  "changelog sections and #{DISCUSSION_URL}"
    end
  end
end
