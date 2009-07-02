module SoapResponseFixture

  def some_soap_response
    '<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
      <soap:Body>
        <ns2:authenticateResponse xmlns:ns2="http://v1_0.ws.example.com/">
          <return>
            <authValue>
              <token>secret</token>
              <client>example</client>
            </authValue>
          </return>
        </ns2:authenticateResponse>
      </soap:Body>
    </soap:Envelope>'
  end

end