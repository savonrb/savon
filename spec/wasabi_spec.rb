require "spec_helper"

describe Wasabi do

  subject(:wasabi) { Wasabi.new fixture(:authentication).read }

  describe '#service_name' do
    it 'returns the name of the service' do
      expect(wasabi.service_name).to eq('AuthenticationWebServiceImplService')
    end
  end

end
