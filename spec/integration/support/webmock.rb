# frozen_string_literal: true

require "webmock/rspec"

# Integration specs must never touch the real internet: every external
# request is stubbed with WebMock. The local Puma server used by other
# integration specs keeps working because localhost stays allowed.
WebMock.disable_net_connect!(allow_localhost: true)
