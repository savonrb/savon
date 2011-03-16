require 'rexml/document'
require "savon/wsse/certs"
require 'savon/wsse/canonicalizer'

module Savon
  class WSSE
    class Signature
      
      class EmptyCanonicalization < RuntimeError; end
      class MissingCertificate < RuntimeError; end
      
      # For a +Savon::WSSE::Certs+ object. To hold the certs we need to sign.
      attr_accessor :certs
      
      # Without a document, the document cannot be signed.
      # Generate the document once, and then set document and recall #to_xml
      attr_accessor :document
      
      ExclusiveXMLCanonicalizationAlgorithm = 'http://www.w3.org/2001/10/xml-exc-c14n#'.freeze
      RSASHA1SignatureAlgorithm = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1'.freeze
      SHA1DigestAlgorithm = 'http://www.w3.org/2000/09/xmldsig#sha1'.freeze
      
      X509v3ValueType = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-x509-token-profile-1.0#X509v3'.freeze
      Base64EncodingType = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary'.freeze
      
      SignatureNamespace = 'http://www.w3.org/2000/09/xmldsig#'.freeze
      
      def initialize(certs = Certs.new)
        @certs = certs
      end
      
      def have_document?
        !!document
      end

      # Cache "now" so that digests match...
      # TODO: figure out how we might want to expire this cache...
      def now
        @now ||= Time.now
      end
      
      def timestamp_id
        @timestamp_id ||= "Timestamp-#{uid}".freeze
      end
      
      def body_id
        @body_id ||= "Body-#{uid}".freeze
      end
      
      def security_token_id
        @security_token_id ||= "SecurityToken-#{uid}".freeze
      end
      
      def body_attributes
        {
          "xmlns:wsu" => WSUNamespace,
          "wsu:Id" => body_id,
        }
      end
      
      def to_xml
        security = {}.deep_merge(timestamp).deep_merge(signature)
        security.deep_merge!(binary_security_token) if certs.cert

        security.merge! :order! => []
        [ "wsu:Timestamp", "wsse:BinarySecurityToken", "Signature" ].each do |key|
          security[:order!] << key if security[key]
        end

        xml = Gyoku.xml({
          "wsse:Security" => security,
          :attributes! => { "wsse:Security" => {
             'xmlns:wsse' => WSENamespace,
             'soapenv:mustUnderstand' => "1",
          } },
        })
      end
      
    private
    
      def binary_security_token
        {
          "wsse:BinarySecurityToken" => Base64.encode64(certs.cert.to_der).gsub("\n", ''),
          :attributes! => { "wsse:BinarySecurityToken" => {
            "wsu:Id" => security_token_id,
            'EncodingType' => Base64EncodingType,
            'ValueType' => X509v3ValueType,
            "xmlns:wsu" => WSUNamespace,
          } }
        }
      end
    
      def signature
        return {} unless have_document?
        
        sig = signed_info.merge(key_info).merge(signature_value)
        sig.merge! :order! => []
        [ "SignedInfo", "SignatureValue", "KeyInfo" ].each do |key|
          sig[:order!] << key if sig[key]
        end

        {
          "Signature" => sig,
          :attributes! => { "Signature" => { "xmlns" => SignatureNamespace } },
        }
      end
    
      def key_info
        {
          "KeyInfo" => {
            "wsse:SecurityTokenReference" => {
              "wsse:Reference/" => nil,
              :attributes! => { "wsse:Reference/" => {
                "ValueType" => X509v3ValueType,
                "URI" => "##{security_token_id}",
              } }
            },
            :attributes! => { "wsse:SecurityTokenReference" => { "xmlns" => "" } },
          },
        }
      end
      
      def signature_value
        { "SignatureValue" => the_signature }
      rescue EmptyCanonicalization, MissingCertificate
        {}
      end
    
      def signed_info
        {
          "SignedInfo" => {
            "CanonicalizationMethod/" => nil,
            "SignatureMethod/" => nil,
            "Reference" => [
              { "DigestValue" => timestamp_digest }.merge(signed_info_transforms).merge(signed_info_digest_method),
              { "DigestValue" => body_digest }.merge(signed_info_transforms).merge(signed_info_digest_method),
            ],
            :attributes! => {
              "CanonicalizationMethod/" => { "Algorithm" => ExclusiveXMLCanonicalizationAlgorithm },
              "SignatureMethod/" => { "Algorithm" => RSASHA1SignatureAlgorithm },
              "Reference" => { "URI" => ["##{timestamp_id}", "##{body_id}"] },
            },
            :order! => [ "CanonicalizationMethod/", "SignatureMethod/", "Reference" ],
          },
        }
      end
    
      # We're going to generate the timestamp ourselves, since WSSE is hard-
      # coded to generate the timestamp section directly within wsse:Security.
      #
      # TODO: Allow for configurability of these timestamps.
      def timestamp
        {
          "wsu:Timestamp" => {
            "wsu:Created" => now.xs_datetime,
            "wsu:Expires" => (now + 60 * 5).xs_datetime,
            :order! => ["wsu:Created", "wsu:Expires"],
          },
          :attributes! => { "wsu:Timestamp" => { "wsu:Id" => timestamp_id, "xmlns:wsu" => WSUNamespace } },
        }
      end
      
      def the_signature
        raise MissingCertificate, "Expected a private_key for signing" unless certs.private_key
        xml = canonicalize("SignedInfo")
        signature = certs.private_key.sign(OpenSSL::Digest::SHA1.new, xml)
        Base64.encode64(signature).gsub("\n", '') # TODO: DRY calls to Base64.encode64(...).gsub("\n", '')
      end
      
      def timestamp_digest
        xml_digest('wsu:Timestamp')
      end
      
      def body_digest
        xml_digest("soapenv:Body")
      end

      def canonicalize(xml_element)
        canonicalized_element = Canonicalizer.canonicalize(document, xml_element)
        raise EmptyCanonicalization, "Expected to canonicalize #{xml_element.inspect} within: #{document}" if canonicalized_element.blank?
        canonicalized_element
      end

      def xml_digest(xml_element)
        Base64.encode64(OpenSSL::Digest::SHA1.digest(canonicalize(xml_element))).strip
      end
      
      def signed_info_digest_method
        { "DigestMethod/" => nil, :attributes! => { "DigestMethod/" => { "Algorithm" => SHA1DigestAlgorithm } } }
      end
    
      def signed_info_transforms
        { "Transforms" => { "Transform/" => nil, :attributes! => { "Transform/" => { "Algorithm" => ExclusiveXMLCanonicalizationAlgorithm } } } }
      end
      
      def uid
        OpenSSL::Digest::SHA1.hexdigest([Time.now, rand].collect(&:to_s).join('/'))
      end
    end
  end
end
