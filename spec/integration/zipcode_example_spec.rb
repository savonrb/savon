# frozen_string_literal: true
require "spec_helper"

RSpec.describe "ZIP code example" do
  let(:expected) { ["seventy million seventy thousand ten ", "twenty four million fifty thousand one hundred and ten ", "twenty million fifty thousand five hundred and fifty "] }
  let(:request_data) { [70070010, 24050110, 20050550] }

  let(:client) {
    Savon.client(
      wsdl: "https://www.dataaccess.com/webservicesserver/NumberConversion.wso?wsdl",
      ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE,
      # Lower timeouts so these specs don't take forever when the service is not available.
      open_timeout: 10,
      read_timeout: 10,
      log: false # Disable logging for cleaner spec output.
    )
  }
  let(:mutex) { Mutex.new }
  it "supports threads making requests simultaneously" do
    threads_waiting = request_data.size
    threads = request_data.map do |blz|
      thread = Thread.new do
        response = call_and_fail_gracefully(client, :number_to_words, :message => { :ubi_num => blz })
        Thread.current[:value] = response.body[:number_to_words_response][:number_to_words_result]
        mutex.synchronize { threads_waiting -= 1 }
      end

      thread.abort_on_exception = true
      thread
    end

    sleep(1) until threads_waiting == 0

    threads.each(&:kill)
    values = threads.map { |thr| thr[:value] }.compact

    expect(values).to match_array(expected)
  end
end
