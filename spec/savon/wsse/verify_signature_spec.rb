require "spec_helper"

describe Savon::WSSE::VerifySignature do
    
  let(:response) { soap_response(:body => Fixture.response(:signed_request)) }
  let(:signature) { Savon::WSSE::VerifySignature.new(response.http.body) }
  
  it "should be valid" do
    signature.should be_valid
  end
  
  let(:security_section) { response.basic_hash["env:Envelope"]["soapenv:Header"]["wsse:Security"] }
  
  context 'the signaturevalue' do
    let(:signature_value) { security_section["Signature"]["SignatureValue"] }
    let(:certificate) { OpenSSL::X509::Certificate.new(Base64.decode64(security_section["wsse:BinarySecurityToken"])) }
    
    it "should grab the correct signature value" do
      signature.signature_value.should == signature_value
    end
    
    it "should grab the correct certificate" do
      signature.certificate.serial.should == certificate.serial
    end
  end

  describe '#verify!' do
    context 'when the signature is valid' do
      before { signature.stubs(:verify).returns(true) }
      it "does not raise" do
        expect { signature.verify! }.to_not raise_error
      end
    end
    
    context 'when the signature is not valid' do
      before { signature.stubs(:verify).raises(Savon::WSSE::VerifySignature::InvalidDigest) }
      it "raises an InvalidSignature" do
        expect { signature.verify! }.to raise_error(Savon::WSSE::InvalidSignature)
      end
    end
  end

  context 'the digests' do
    
    { :timestamp => '//wsse:Security//wsu:Timestamp', :body => '//env:Body[@Id@=Body]' }.each do |section, xpath|
      context "the #{section} section" do
        let(:supplied_digest) { security_section["Signature"]["SignedInfo"]["Reference"].find { |t| t["URI"].match /#{section}/i }["DigestValue"] }

        it "should find the digest" do
          signature.supplied_digest(xpath).should == supplied_digest
        end
  
        it "should generate the correct digest" do
          signature.generate_digest(xpath).should == supplied_digest
        end
  
  
        it "should have the have the same supplied digest as generated digest" do
          signature.generate_digest(xpath).should == signature.supplied_digest(xpath)
        end
        
        it "should generate the same digest twice" do
          signature.generate_digest(xpath).should == signature.generate_digest(xpath)
        end
        
      end
    end
  
  end
  
  def soap_response(options = {})
    defaults = { :code => 200, :headers => {}, :body => Fixture.response(:authentication) }
    response = defaults.merge options

    Savon::SOAP::Response.new HTTPI::Response.new(response[:code], response[:headers], response[:body])
  end
end