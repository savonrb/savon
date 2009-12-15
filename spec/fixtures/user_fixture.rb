class UserFixture

  @namespace_uri = "http://v1_0.ws.user.example.com"
  @operations = {
    :user_find_by_id => { :action => "User.FindById", :input => "User.FindById" },
    :find_user => { :action => "findUser", :input => "findUser" }
  }

  @datetime_string = "2010-11-22T11:22:33"
  @datetime_object = DateTime.parse @datetime_string

  @response_hash = {
    :ns2 => "http://v1_0.ws.user.example.com",
    :return => {
      :active => true,
      :firstname => "The",
      :lastname => "Dude",
      :email => "thedude@example.com",
      :id => "666",
      :registered => @datetime_object,
      :username => "thedude"
    }
  }

  class << self

    attr_accessor :namespace_uri, :operations,
      :datetime_string, :datetime_object, :response_hash

    def soap_actions
      @operations.keys
    end

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
    
    def soap_fault12
      load_fixture :soap_fault12
    end

  private

    def load_fixture(file)
      file_path = File.join File.dirname(__FILE__), "#{file}.xml"
      IO.readlines(file_path, "").to_s
    end

  end
end
