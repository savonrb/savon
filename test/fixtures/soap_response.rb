module SoapResponseFixture

  def some_soap_response
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' <<
      '<soap:Body>' <<
        '<ns2:result xmlns:ns2="http://example.com/">' <<
          '<return>' <<
            '<token>secret</token>' <<
          '</return>' <<
        '</ns2:result>' <<
      '</soap:Body>' <<
    '</soap:Envelope>'
  end

  def soap_fault_response
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">' <<
       '<soap:Body>' <<
          '<soap:Fault>' <<
             '<faultcode>' << soap_fault_code << '</faultcode>' <<
             '<faultstring>' << soap_fault << '</faultstring>' <<
          '</soap:Fault>' <<
       '</soap:Body>' <<
    '</soap:Envelope>'
  end

  def soap_fault
    "Failed to authenticate client."
  end

  def soap_fault_code
    "soap:Server"
  end

end