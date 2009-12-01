class UserFixture

  @namespace_uri = "http://v1_0.ws.user.example.com"
  @soap_action_map = {
    :user_find_by_id => { :name => "User.FindById", :input => "User.FindById" },
    :find_user => { :name => "findUser", :input => "findUser" }
  }

  @datetime_string = "2010-11-22T11:22:33"
  @datetime_object = DateTime.parse @datetime_string

  @response_hash = { :id => "666", :active => true, :username => "thedude",
    :firstname => "The", :lastname => "Dude", :email => "thedude@example.com",
    :registered => @datetime_object }

  class << self

    attr_accessor :namespace_uri, :soap_action_map,
      :datetime_string, :datetime_object, :response_hash

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
