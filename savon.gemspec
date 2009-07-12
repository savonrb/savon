Gem::Specification.new do |s|
  s.name = "savon"
  s.version = "0.0.8"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.author = "Daniel Harrington"
  s.description = "Savon is a lightweight SOAP client."
  s.homepage = "http://github.com/smacks/savon"
  s.summary = "Savon is a lightweight SOAP client."

  s.has_rdoc = true
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "lib/savon.rb", "lib/savon/service.rb", "lib/savon/wsdl.rb",
    "lib/savon/response.rb", "lib/savon/mash.rb"]
  s.test_files = ["test/savon_test.rb","test/helper.rb", "test/factories/wsdl.rb",
    "test/fixtures/soap_response.rb", "test/savon/service_test.rb", "test/savon/response_test.rb",
    "test/savon/wsdl_test.rb", "test/savon/mash_test.rb"]

  s.requirements << 'mocha and shoulda for testing'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new("1.2.0") then
      s.add_runtime_dependency("hpricot", "0.6.164")
      s.add_runtime_dependency("smacks-apricoteatsgorilla", ">= 0.3.8")
    else
      s.add_dependency("hpricot", "0.6.164")
      s.add_dependency("smacks-apricoteatsgorilla", ">= 0.3.8")
    end
  else
    s.add_dependency("hpricot", "0.6.164")
    s.add_dependency("smacks-apricoteatsgorilla", ">= 0.3.8")
  end
end