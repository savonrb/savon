# frozen_string_literal: true
require "spec_helper"

RSpec.describe "ZIP code example" do
  it "supports threads making requests simultaneously" do
    client = Savon.client(
      :wsdl => "http://www.thomas-bayer.com/axis2/services/BLZService?wsdl",

      # Lower timeouts so these specs don't take forever when the service is not available.
      :open_timeout => 10,
      :read_timeout => 10,

      :log => false # Disable logging for cleaner spec output.
    )

    mutex = Mutex.new

    request_data = [70070010, 24050110, 20050550]
    threads_waiting = request_data.size

    threads = request_data.map do |blz|
      thread = Thread.new do
        response = call_and_fail_gracefully(client, :get_bank, :message => { :blz => blz })
        Thread.current[:value] = response.body[:get_bank_response][:details]
        mutex.synchronize { threads_waiting -= 1 }
      end

      thread.abort_on_exception = true
      thread
    end

    sleep(1) until threads_waiting == 0

    threads.each(&:kill)
    values = threads.map { |thr| thr[:value] }.compact

    expect(values.uniq.size).to eq(values.size)
  end
end
