require "spec_helper"

describe Savon::Hooks::Group do

  let(:group) { subject }

  describe "#empty?" do
    it "returns true for an empty group" do
      group.should be_empty
    end

    it "returns false if the group contains hooks" do
      group = Savon::Hooks::Group.new [:some_hook]
      group.should_not be_empty
    end
  end

  describe "#define" do
    it "lets you define a new hook" do
      group.define(:test_hook, :soap_request)
      group.should_not be_empty
    end

    it "raises if there is no such hook" do
      expect { group.define(:supposed_to_fail, :no_such_hook) }.to raise_error(ArgumentError)
    end
  end

  describe "#reject" do
    it "rejects hooks matching any given id" do
      group.define(:remove1, :soap_request)
      group.define(:here_to_stay, :soap_request)
      group.define(:remove2, :soap_request)
      group.count.should == 3

      group.reject(:remove1, :remove2)
      group.count.should == 1
    end
  end

  describe "#fire" do
    let(:hook)     { lambda {} }
    let(:fallback) { lambda {} }

    context "with hooks" do
      before do
        group.define(:some_hook, :soap_request, &hook)
      end

      it "calls the hooks passing any arguments" do
        hook.expects(:call).with(:arg1, :arg2)
        group.fire(:soap_request, :arg1, :arg2)
      end

      it "calls the hooks passing any arguments and the callback" do
        hook.expects(:call).with(fallback, :arg)
        group.fire(:soap_request, :arg, &fallback)
      end
    end

    context "without hooks" do
      it "executes the callback" do
        report = :call
        fallback = lambda { report = :back }
        group.fire(:soap_request, &fallback)
        report.should == :back
      end
    end
  end

end
