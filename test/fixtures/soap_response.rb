module SoapResponseFixture

  def some_response_hash
    {
      :authentication => {
        :user => "example",
        :password => "secret"
      },
      :success => true,
      :tokens => ["abc", "xyz", "123"]
    }
  end

  def response_hash_with_id
    some_response_hash.dup.update :id => "shadow_id"
  end

  def response_hash_with_inspect
    some_response_hash.dup.update :inspect => "shadow_inspect"
  end

  def some_soap_response
    build_soap_response
  end

  def soap_response_with_id
    build_soap_response '<id>shadow_id</id>'
  end

  def soap_response_with_inspect
    build_soap_response '<inspect>shadow_inspect</inspect>'
  end

  def soap_fault_response
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' <<
       '<soap:Body>' <<
          '<soap:Fault>' <<
             '<faultcode>' << soap_fault_code << '</faultcode>' <<
             '<faultstring>' << soap_fault_message << '</faultstring>' <<
          '</soap:Fault>' <<
       '</soap:Body>' <<
    '</soap:Envelope>'
  end

  def soap_fault_message
    "Failed to authenticate client."
  end

  def soap_fault_code
    "soap:Server"
  end

private

  def build_soap_response(mixin = "")
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' <<
      '<soap:Body>' <<
        '<ns2:result xmlns:ns2="http://example.com/">' <<
          '<return>' <<
            '<authentication>' <<
              '<user>example</user>' <<
              '<password>secret</password>' <<
            '</authentication>' <<
            mixin <<
            '<success>true</success>' <<
            '<tokens>abc</tokens>' <<
            '<tokens>xyz</tokens>' <<
            '<tokens>123</tokens>' <<
          '</return>' <<
        '</ns2:result>' <<
      '</soap:Body>' <<
    '</soap:Envelope>'
  end

end