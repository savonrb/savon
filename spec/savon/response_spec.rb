require 'spec_helper'

describe Savon::Response do
  subject(:response) do
    response = Savon::Response.new(nil)
    response.send(:instance_variable_set, :@hash, {
      :envelope => {:header => 'the-spice-must-flow'}
    })
    response
  end

  describe '#headers' do
    it 'returns the headers for the underlying response' do
      expect(response.header).to eq('the-spice-must-flow')
    end
  end
end
