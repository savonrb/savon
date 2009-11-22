class UserFixture

  @namespace_uri = "http://v1_0.ws.user.example.com"
  @soap_actions = { :find_user => "findUser" }

  @soap_response_hash_id = { "$" => "666" }
  @soap_response_hash_username = { "$" => "thedude" }
  @soap_response_hash_email = { "$" => "thedude@example.com" }
  @soap_response_hash_registered = { "$" => DateTime.new(2000, 01, 22, 22, 11, 21) }

  class << self

    attr_accessor :namespace_uri, :soap_actions,
      :soap_response_hash_id, :soap_response_hash_username,
      :soap_response_hash_email, :soap_response_hash_registered

    def user_wsdl
      load_fixture :user_wsdl
    end

    def user_response
      load_fixture :user_response
    end

    def multiple_user_response
      load_fixture :multiple_user_response
    end

    def soap_fault
      load_fixture :soap_fault
    end

  private

    def load_fixture(file)
      file_path = File.join File.dirname(__FILE__), "#{file}.xml"
      IO.readlines(file_path, "").to_s
    end

  end
end