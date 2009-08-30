Gem::Specification.new do |s|
  s.name = "savon"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.author = "Daniel Harrington"
  s.email = "me@d-harrington.com"
  s.description = "Ruby SOAP client library to enjoy."
  s.homepage = "http://github.com/smacks/savon"
  s.summary = "Ruby SOAP client library to enjoy."

  s.has_rdoc = true
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = ["README.rdoc", "Rakefile", "lib/savon.rb",
    "lib/savon/service.rb", "lib/savon/wsdl.rb"]
  s.test_files = ["test/helper.rb", "test/factories/wsdl.rb",
    "test/fixtures/soap_response.rb", "test/savon/test_service.rb",
    "test/savon/test_wsdl.rb"]

  s.requirements << "mocha and shoulda for testing"

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new("1.2.0") then
      s.add_runtime_dependency("hpricot", "0.6.164")
      s.add_runtime_dependency("smacks-apricoteatsgorilla", "0.4.9")
    else
      s.add_dependency("hpricot", "0.6.164")
      s.add_dependency("smacks-apricoteatsgorilla", "0.4.9")
    end
  else
    s.add_dependency("hpricot", "0.6.164")
    s.add_dependency("smacks-apricoteatsgorilla", "0.4.9")
  end
end