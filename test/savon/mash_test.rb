require File.join(File.dirname(__FILE__), "..", "helper")

class SavonMashTest < Test::Unit::TestCase

  context "Creating a new Savon::Mash" do
    context "with a simple Hash" do
      should "return a Mash object matching the given Hash" do
        hash = { :some => { :simple => "test" } }
        mash = Savon::Mash.new(hash)

        assert_respond_to(mash, :some)
        assert_respond_to(mash, :simple)
        assert_equal "test", mash.some.simple
      end
    end
  end

end