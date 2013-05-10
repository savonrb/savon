require "spec_helper"

describe Wasabi do

  subject(:wasabi) { Wasabi.new fixture(:authentication).read }

  describe '#service_name' do
    it 'returns the name of the service' do
      expect(wasabi.service_name).to eq('AuthenticationWebServiceImplService')
    end
  end

  describe '#inspect' do
    it 'returns information about the service' do
      expect(wasabi.inspect.to_hash).to include(
        :service_name     => "AuthenticationWebServiceImplService",
        :target_namespace => "http://v1_0.ws.auth.order.example.com/"
      )
    end
  end

end
