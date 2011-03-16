module Savon
  class WSSE
    # Contains certs for WSSE::Signature
    class Certs
      
      def initialize(certs = {})
        certs.each do |key, value|
          self.send :"#{key}=", value
        end
      end
      
      attr_accessor :cert_file, :private_key_file, :private_key_password
      
      # Returns an <tt>OpenSSL::X509::Certificate</tt> for the +cert_file+.
      def cert
        @cert ||= OpenSSL::X509::Certificate.new File.read(cert_file) if cert_file
      end

      # Returns an <tt>OpenSSL::PKey::RSA</tt> for the +private_key_file+.
      def private_key
        @private_key ||= OpenSSL::PKey::RSA.new(File.read(private_key_file), private_key_password) if private_key_file
      end
    end
  end
end