# frozen_string_literal: true

require "spec_helper"
require "integration/support/webmock"

# Regression coverage built from real-world WSDLs captured as fixtures in
# spec/integration/fixtures/real_world/. Every fixture is byte-faithful to
# what the remote server returned; WebMock blocks all network access, so
# these specs are fully hermetic.
RSpec.describe "Real-world WSDLs" do
  def real_world_wsdl(name)
    File.expand_path("fixtures/real_world/#{name}", __dir__)
  end

  def real_world_client(name, **options)
    Savon.client({ wsdl: real_world_wsdl(name), log: false }.merge(options))
  end

  describe "Marketo (issue #634)" do
    # Savon > 2.4.0 mangled the document/literal wrapped input element
    # <tns:paramsSyncLead> into <tns:syncLead>; 2.4.0 generated the
    # correct element name. Guards against that regression.
    it "generates the wrapped input element name, not the stripped operation name" do
      client = real_world_client("marketo.wsdl")
      expect(client.operations).to include(:sync_lead)

      body = client.build_request(:sync_lead, message: { return_lead: true }).body
      expect(body).to include("<tns:paramsSyncLead>")
      expect(body).not_to match(/<tns:syncLead>/)
    end
  end

  describe "Juniper booking engine (issue #879)" do
    # The WSDL exposes 12 ports on different endpoint URLs, but savon has
    # never routed operations to their own port's endpoint (#879, open):
    # every request goes to the first port's address. These specs pin the
    # parsing side (operations from every portType are visible) and
    # document the endpoint behavior, so a future fix knows where to start.
    it "exposes operations from every portType" do
      client = real_world_client("juniper_879.wsdl")

      expect(client.operations.size).to be > 80
      expect(client.operations).to include(:hotel_list_inventory, :hotel_booking, :check_payment)
    end

    it "resolves the endpoint to the first port's address" do
      client = real_world_client("juniper_879.wsdl")

      expect(client.wsdl.endpoint.to_s)
        .to eq("http://xml2.bookingengine.es/webservice/jp/operations/booktransactions.asmx")
    end
  end

  describe "Bing Ads CampaignManagement v13 (issue #895)" do
    # 1.2MB, 217 namespaces. #895: elements typed in the
    # Serialization/Arrays namespace (e.g. <long>) were emitted with the tns:
    # prefix instead of ins0:, because the key-converted message keys
    # ("entityIds") never matched the schema element names ("EntityIds") in
    # the type-namespace lookups. Guards the fix.
    it "prefixes schema-typed elements with their own namespace" do
      client = real_world_client("bing_ads_v13.wsdl")
      expect(client.operations).to include(:get_ad_extensions_associations)

      body = client.build_request(
        :get_ad_extensions_associations,
        message: {
          account_id: 150_168_726,
          association_type: "Campaign",
          ad_extension_type: "CallAdExtension",
          entity_ids: [{ long: 8_177_659_860_409 }]
        }
      ).body

      expect(body).to include("<tns:GetAdExtensionsAssociationsRequest>")
      expect(body).to include("<ins0:long>8177659860409</ins0:long>")
      expect(body).not_to include("<tns:long>")
    end
  end

  describe "ExactTarget / Marketing Cloud (issue #439)" do
    # The server silently accepts default-namespaced requests but returns a
    # fake success; only namespace_identifier: nil makes requests actually
    # execute. Guards that the option keeps working against this WSDL.
    it "emits unprefixed body elements with namespace_identifier nil" do
      client = real_world_client("exacttarget.wsdl", namespace_identifier: nil)

      body = client.build_request(:create, message: { objects: { name: "x" } }).body
      expect(body).to include("<CreateRequest>")
      expect(body).not_to include("<tns:CreateRequest>")
    end

    it "emits prefixed body elements by default" do
      client = real_world_client("exacttarget.wsdl")

      body = client.build_request(:create, message: { objects: { name: "x" } }).body
      expect(body).to include("<tns:CreateRequest>")
    end
  end

  describe "parser torture WSDLs" do
    # No direct savon issues; these are large, gnarly real-world WSDLs that
    # smoke-test the parser against regressions.
    {
      "workday_hr.wsdl"         => :get_organization,
      "netsuite_2024_1.wsdl"    => :search,
      "salesforce_partner.wsdl" => :login
    }.each do |wsdl, operation|
      it "parses #{wsdl} and exposes #{operation}" do
        client = real_world_client(wsdl)

        expect(client.operations).not_to be_empty
        expect(client.operations).to include(operation)
      end
    end
  end
end
