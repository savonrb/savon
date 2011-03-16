require "spec_helper"
# require 'savon/wsse/canonicalizer'

describe Savon::WSSE::Signature do
  
  let(:certs) { Savon::WSSE::Certs.new :cert_file => Fixture.cert_path("cert"), :private_key_file => Fixture.cert_path("cert") }
  let(:signature) { Savon::WSSE::Signature.new }
  
  describe '#timestamp_id' do
    it "should give the same value twice" do
      signature.timestamp_id.should == signature.timestamp_id
    end
    
    it "should be unique to it's class" do
      signature.timestamp_id.should_not == Savon::WSSE::Signature.new.timestamp_id
    end
    
    it "starts with Timestamp" do
      signature.timestamp_id.should match(/^Timestamp-/)
    end
  end
  
  describe '#body_id' do
    it "should give the same value twice" do
      signature.body_id.should == signature.body_id
    end
    
    it "should be unique to it's class" do
      signature.body_id.should_not == Savon::WSSE::Signature.new.body_id
    end
    
    it "starts with Body" do
      signature.body_id.should match(/^Body-/)
    end
  end
  
  describe '#security_token_id' do
    it "should give the same value twice" do
      signature.security_token_id.should == signature.security_token_id
    end
    
    it "should be unique to it's class" do
      signature.security_token_id.should_not == Savon::WSSE::Signature.new.security_token_id
    end
    
    it "starts with SecurityToken" do
      signature.security_token_id.should match(/^SecurityToken-/)
    end
  end
  
  describe '#body_attributes' do
    it "should have a unique id" do
      signature.body_attributes["wsu:Id"].should match(/^Body-\w+$/)
    end
    
    it "should include some fancy namespace for wsu" do
      signature.body_attributes["xmlns:wsu"].should == "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
    end
  end

  context 'with certs' do
    before { signature.certs = certs }
  
    it "should have a cert" do
      signature.certs.cert.should be_kind_of(OpenSSL::X509::Certificate)
    end
  
    it "should have a cert key" do
      signature.certs.private_key.should be_kind_of(OpenSSL::PKey::RSA)
    end
  end
  

  
  describe '#to_xml' do
  
    context 'with a body' do
      let(:soap) { Savon::SOAP::XML.new }
      let(:wsse) { Savon::WSSE.new }
      before do
        wsse.sign_with = signature
        soap.wsse = wsse
        
        soap.body = "This is the soap body"
        signature.document = soap.to_xml(true)
      end
      
      # NOTE: This test is fragile because of argument ordering
      it "should include the wsse:Security section" do
        signature.to_xml.should match(%r{<wsse:Security xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" soapenv:mustUnderstand="1">.*</wsse:Security>})
      end

      # NOTE: This test is fragile because of argument ordering
      it "should add the timestamp" do
        signature.to_xml.should match(%r{<wsu:Timestamp wsu:Id="Timestamp-[^"]+" xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"><wsu:Created>#{Savon::SOAP::DateTimeRegexp}\w*</wsu:Created><wsu:Expires>#{Savon::SOAP::DateTimeRegexp}\w*</wsu:Expires></wsu:Timestamp>})
      end
      
      it "should have a signed info section within Signature" do
        signature.to_xml.should match(%r{<Signature.*<SignedInfo>.*</SignedInfo>.*</Signature>})
      end
      
      it "should have a signature with a xml namespace" do
        signature.to_xml.should match(%r{<Signature\s+xmlns="http://www.w3.org/2000/09/xmldsig#"})
      end
      
      context 'the signed info section' do
        before {
          signature.to_xml.match(%r{<SignedInfo>(.*)</SignedInfo>})
          @signed_info_section = $1
        }
        
        subject { @signed_info_section }
        
        it "exists" do
          subject.should_not be_nil
        end
        
        it "has a CanonicalizationMethod" do
          subject.should match(%r{<CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>})
        end
        
        it "has a SignatureMethod" do
          subject.should match(%r{<SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>})
        end

        shared_examples_for 'a digest reference' do
          it "exists" do
            subject.should_not be_nil
          end
          
          # Sanity check that we did not match the whole of references
          it "does not contain another Reference" do
            subject.should_not match(/<Reference/)
          end
          
          it "has transforms" do
            subject.should match(%r{<Transforms>\s*<Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>\s*</Transforms>})
          end
          
          it "has a digest method" do
            subject.should match(%r{<DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>})
          end
        end

        context 'the Timestamp digest' do
          before {
            @signed_info_section.match(%r{<Reference URI="##{signature.timestamp_id}">(.+?)</Reference>})
            @timestamp_section = $1
          }
          subject { @timestamp_section }
          
          it_should_behave_like "a digest reference"
          
          it "has a digest value" do
            canonicalized_timestamp = Savon::WSSE::Canonicalizer.canonicalize(signature.document, "wsu:Timestamp")
            expected_digest_value = Base64.encode64(OpenSSL::Digest::SHA1.digest(canonicalized_timestamp)).strip
            subject.should match(%r{<DigestValue>#{Regexp.escape(expected_digest_value)}</DigestValue>})
          end
        end

        context 'the Body digest' do
          before {
            @signed_info_section.match(%r{<Reference URI="##{signature.body_id}">(.+?)</Reference>})
            @body_section = $1
          }
          subject { @body_section }
          
          it_should_behave_like "a digest reference"
          
          it "has a digest value" do
            canonicalized_body = Savon::WSSE::Canonicalizer.canonicalize(signature.document, "env:Body")
            expected_digest_value = Base64.encode64(OpenSSL::Digest::SHA1.digest(canonicalized_body)).strip
            subject.should match(%r{<DigestValue>#{Regexp.escape(expected_digest_value)}</DigestValue>})
          end
        end
      end
      
      
      context 'with certs' do
        before { signature.certs = certs }

        context 'the binary security token' do
          before do
            @binary_security_token_element = signature.to_xml[%r{<wsse:BinarySecurityToken.*</wsse:BinarySecurityToken>}]
          end
          subject { @binary_security_token_element }
          
          it "exists" do
            subject.should_not be_nil
          end
        
          it "has a Base64 encoding type" do
            subject.should match(%r{<wsse:BinarySecurityToken[^>]+EncodingType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary"})
          end
          
          it "has an X509v3 value type" do
            subject.should match(%r{<wsse:BinarySecurityToken[^>]+ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"})
          end
          
          it "has the WSU namespace" do
            subject.should match(%r{<wsse:BinarySecurityToken[^>]+xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"})
          end

          it "has an id" do
            subject.should match(%r{<wsse:BinarySecurityToken[^>]+wsu:Id="SecurityToken-[^" ]+"})
          end
          
          it "includes the cert" do
            b64cert = Base64.encode64(certs.cert.to_der).gsub("\n", '')
            subject.should match(%r{<[^>]+>#{Regexp.escape b64cert}</[^>]+>})
          end
        end
        
        context 'the signature value' do
          before do
            # Generate xml one more time
            signature.document = soap.to_xml(true)
            
            signature.to_xml.match(%r{<SignatureValue>(.+)</SignatureValue>})
            @signature_value = $1
          end
          subject { @signature_value }
          
          it "exists" do
            subject.should_not be_nil
          end
          
          it "canonicalizes something" do
            canonicalized_signature = Savon::WSSE::Canonicalizer.canonicalize(signature.document, "SignedInfo")
            canonicalized_signature.should_not be_blank
          end
          
          it "is correct"
            # expected_digest_value = Base64.encode64(OpenSSL::Digest::SHA1.digest(canonicalized_timestamp)).strip
        end
        
        context 'the key info section' do
          subject { signature.to_xml[%r{<KeyInfo>.+</KeyInfo>}] }
          
          it "exists" do
            subject.should_not be_nil
          end
          
          it "should reference the SecurityToken id" do
            subject.should match(%r{<wsse:Reference[^>]+URI="##{signature.security_token_id}"})
          end
          
          it "should have a Reference with an X509 value type" do
            subject.should match(%r{<wsse:Reference[^>]+ValueType="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3"})
          end
          
          it "should have the correct? structure" do
            subject.should match(%r{^<KeyInfo><wsse:SecurityTokenReference xmlns=""><wsse:Reference})
          end
        end
      end
    end
  end
end