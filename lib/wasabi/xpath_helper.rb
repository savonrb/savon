module Wasabi
  module XPathHelper

    NAMESPACES = {
      "xs"     => "http://www.w3.org/2001/XMLSchema",
      "wsdl"   => "http://schemas.xmlsoap.org/wsdl/",
      "soap11" => "http://schemas.xmlsoap.org/wsdl/soap/",
      "soap12" => "http://schemas.xmlsoap.org/wsdl/soap12/"
    }

    def xpath(*args)
      node, xpath = extract_xpath_args(args)
      node.xpath(xpath, NAMESPACES)
    end

    def at_xpath(*args)
      node, xpath = extract_xpath_args(args)
      node.at_xpath(xpath, NAMESPACES)
    end

  private

    def extract_xpath_args(args)
      xpath, target = args.reverse
      target ||= document if respond_to?(:document)
      [target, xpath]
    end

  end
end
