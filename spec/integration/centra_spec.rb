require 'spec_helper'

module LogInterceptor
  @@intercepted_request = ""
  def self.debug(message)
    # save only the first XMLly message
    if message.include? "xml version"
      @@intercepted_request = message if @@intercepted_request == ""
    end
  end

  def self.info(message)
  end

  def self.get_intercepted_request
    @@intercepted_request
  end

  def self.reset_intercepted_request
    @@intercepted_request = ""
  end
end

describe 'Correct translation of attributes to XML' do
  it "new :@attr syntax: correctly maps a Ruby Hash to XML attributes" do
    LogInterceptor.reset_intercepted_request

    client = Savon.client(
      :wsdl => "http://mt205.sabameeting.com/CWS/CWS.asmx?WSDL",
      :logger => LogInterceptor
    )

    response = nil
    begin
      response = call_and_fail_gracefully(client, :add_new_user, :message => { :user => { :@userID => "test" } })
    rescue
    end

    xml_doc = Nokogiri::XML(LogInterceptor.get_intercepted_request)
    xml_doc.remove_namespaces!

    attributes_element_not_present = xml_doc.xpath("//AddNewUser/attributes").blank?

    puts "new syntax: attributes element not present: " + attributes_element_not_present.to_s

    expect(attributes_element_not_present).to eq true
  end
  
  it "old :attributes! syntax: correctly maps a Ruby Hash to XML attributes" do
    LogInterceptor.reset_intercepted_request

    client = Savon.client(
      :wsdl => "http://mt205.sabameeting.com/CWS/CWS.asmx?WSDL",
      :logger => LogInterceptor
    )

    response = nil
    begin
      response = call_and_fail_gracefully(client, :add_new_user, :message => { :user => {}, :attributes! => { :user => { :userID => "test" } } })
    rescue
    end

    xml_doc = Nokogiri::XML(LogInterceptor.get_intercepted_request)
    xml_doc.remove_namespaces!

    attributes_element_not_present = xml_doc.xpath("//AddNewUser/attributes").blank?

    puts "new syntax: attributes element not present: " + attributes_element_not_present.to_s

    expect(attributes_element_not_present).to eq true
  end
end
