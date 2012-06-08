require "spec_helper"

describe Wasabi::Document do
  context "with: inherited.xml" do

    subject { Wasabi::Document.new fixture(:inherited).read }

    its(:type_definitions) do
      should include([["Account", "Id"], "ID"])
      should include([["Account", "ProcessId"], "ID"])
      should include([["Account", "CreatedDate"], "dateTime"])
      should include([["Account", "Description"], "string"])
      should include([["Account", "fieldsToNull"], "string"])
    end

  end
end

