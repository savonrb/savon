require 'spec_helper'

describe Wasabi do
  context 'with: economic.wsdl' do

    subject(:wsdl) { Wasabi.new fixture(:economic).read }

    # XXX: this might be useless now that almost everything is parsed lazily.
    it 'has an ok parse-time for huge wsdl files' do
      #profiler = MethodProfiler.observe(Wasabi::Parser)
      expect(wsdl.parser.operations.count).to eq(1511)
      #puts profiler.report
    end

  end
end
