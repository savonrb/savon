class ResponseFixture

  def self.authentication(value = nil)
    case value
      when :to_hash
        { :success => true,
          :authentication_value => {
            :token => "a68d1d6379b62ff339a0e0c69ed4d9cf",
            :token_hash => "AAAJxA;cIedoT;mY10ExZwG6JuKgp2OYKxow==",
            :client => "radclient"
          }
        }
      else
        @@authentication ||= load_fixture :authentication
    end
  end

  def self.soap_fault
    @@soap_fault ||= load_fixture :soap_fault
  end

  def self.soap_fault12
    @@soap_fault12 ||= load_fixture :soap_fault12
  end

  def self.multi_ref
    @@multi_ref ||= load_fixture :multi_ref
  end

private

  def self.load_fixture(fixture)
    File.read File.dirname(__FILE__) + "/xml/#{fixture}.xml"
  end

end
