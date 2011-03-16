module Savon
  class WSSE
    # This canonicalizer uses XMLStarlet (http://xmlstar.sourceforge.net/)
    # to canonicalize xml for us.
    # WARNING: This is terribly hard coded. Mostly the namespaces in xpath...
    # TODO: Someday we should switch to using some ruby library with bindings
    #       to libxml2 (currently none are readily available). Nokogiri has an
    #       unmaintained branch from a couple of versions back with c14n
    #       support, there is also a fork of libxml2 (at
    #       http://rubygems.org/gems/coupa-libxml-ruby) that supports c14n.
    # BEWARE: XMLCanonicalizer (http://rubygems.org/gems/XMLCanonicalizer)
    #         did not work for me!
    class Canonicalizer
      class NoXMLStarlet < RuntimeError; end

      class << self

        # TODO: document how and why this sort of works.
        def canonicalize(document, element)

          can_haz_xmlstarlet? or raise NoXMLStarlet, "Please install xmlstarlet (http://xmlstar.sourceforge.net/) (brew install xmlstarlet / sudo apt-get install xmlstarlet / etc) and ensure you can run it with the command `xml' (ubuntu renames xml to xmlstarlet)"

          # FIXME: We maybe could keep this file around and use it for
          #        mulitple canonicalizations of the same document...
          full_xml = Tempfile.new("xml")
          full_xml.write document.to_s
          full_xml.close

          # Please don't ask, this was so annoying.
          #
          # Ok, I'll tell you anyway:
          # XMLStarlet didn't like xmlns by itself with no colon-something.
          # So, here I am arbitrarily adding x: to namespaces without a colon
          # to match the line (xmlns:x="http://www.w3.org/2000/09/xmldsig#")
          # below. This is terribly specifically hardcoded, and will probably
          # break with some other document... However, for now, it's gotten my
          # request to go through!
          xpath_element_with_namespace = element.respond_to?(:xpath) ? element.xpath.split("/").last : element.split("/").last
          xpath_element_with_namespace = "x:#{xpath_element_with_namespace}" unless xpath_element_with_namespace.match(/:/)

          xpath = Tempfile.new("xpath")
          # WARNING: These namespaces are very app specific.
          #
          # Also, I don't even understand this xpath thing, but I got it to
          # work :)
          xpath.write <<-XML
            <XPath  xmlns:env="http://schemas.xmlsoap.org/soap/envelope/"
                    xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/"
                    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
                    xmlns:wsu="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd"
                    xmlns:x="http://www.w3.org/2000/09/xmldsig#"

                    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                    >
              (//. | //@* | //namespace::*)[ancestor-or-self::#{xpath_element_with_namespace}]
            </XPath>
          XML
          xpath.close

          `xml c14n --exc-without-comments #{full_xml.path} #{xpath.path}`
        ensure
          begin
            # Try to clean up our poop.
            full_xml.unlink
            xpath.unlink
          rescue => e
            puts "Error while unlinking temporary files: #{e.inspect}"
          end
        end

        def can_haz_xmlstarlet?
          # Cache "true". We should only have to do this once.
          @_haz_xmlstarlet ||= begin
            !!(`xml 2>&1`.match /XMLStarlet/)
          end
        end

      end
    end
  end
end