require "spec_helper"

describe Savon::RequestLogger do

  subject            { described_class.new(globals) }
  let(:globals)      { Savon::GlobalOptions.new(:log => true, :pretty_print_xml => true) }
  let(:request) {
    stub('Request',
         :url     => 'http://example.com',
         :headers => [],
         :body    => '<TestRequest />'
        )
  }

  let(:response) {
    stub('Response',
         :code => 200,
         :body => '<TestResponse />'
        )
  }

  before(:each) {
    globals[:logger].level = Logger::DEBUG
  }

  describe '#log_request / #log_response' do
    it 'does not prepare log messages when no logging is needed' do
      begin
        globals[:logger].level = Logger::FATAL

        Savon::LogMessage.expects(:new).never
        subject.log(request) { response }
      end
    end

  end
end
