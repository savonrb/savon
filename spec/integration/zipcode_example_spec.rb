 require "spec_helper"

describe "ZIP code example" do

  subject(:client) {
    Savon.client(:wsdl => service_endpoint, :open_timeout => 10, :read_timeout => 10,
                 :raise_errors => false, :log => false)
  }

  let(:service_endpoint) { "http://www.thomas-bayer.com/axis2/services/BLZService?wsdl" }

  it "supports threads making requests simultaneously" do
    mutex = Mutex.new

    request_data = [70070010, 24050110, 20050550]
    threads_waiting = request_data.size

    threads = request_data.map do |blz|
      thread = Thread.new do
        response = client.call :get_bank, :message => { :blz => blz }
        Thread.current[:value] = response.body[:get_bank_response][:details]
        mutex.synchronize { threads_waiting -= 1 }
      end

      thread.abort_on_exception = true
      thread
    end

    sleep(1) until threads_waiting == 0

    threads.each(&:kill)
    values = threads.map { |thr| thr[:value] }.compact

    values.uniq.size.should == values.size
  end

end
