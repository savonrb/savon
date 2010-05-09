require "spec_helper"

describe Array do

  describe "to_soap_xml" do
    it "should return the XML for an Array of Hashes" do
      array = [{ :name => "adam" }, { :name => "eve" }]
      result = "<user><name>adam</name></user><user><name>eve</name></user>"
      
      array.to_soap_xml("user").should == result
    end

    it "should return the XML for an Array of different Objects" do
      array = [:symbol, "string", 123]
      result = "<value>symbol</value><value>string</value><value>123</value>"
      
      array.to_soap_xml("value").should == result
    end

    it "should default to escape special characters" do
      array = ["<tag />", "adam & eve"]
      result = "<value>&lt;tag /&gt;</value><value>adam &amp; eve</value>"
      
      array.to_soap_xml("value").should == result
    end

    it "should not escape special characters when told to" do
      array = ["<tag />", "adam & eve"]
      result = "<value><tag /></value><value>adam & eve</value>"
      
      array.to_soap_xml("value", false).should == result
    end

    it "should add attributes to a given tag" do
      array = ["adam", "eve"]
      result = '<value active="true">adam</value><value active="true">eve</value>'
      
      array.to_soap_xml("value", :escape_xml, :active => true).should == result
    end

    it "should add attributes to duplicate tags" do
      array = ["adam", "eve"]
      result = '<value id="1">adam</value><value id="2">eve</value>'
      
      array.to_soap_xml("value", :escape_xml, :id => [1, 2]).should == result
    end
  end

end