Gem::Specification.new do |s|
  s.name = "savon"
  s.version = "0.1.5"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.author = "Daniel Harrington"
  s.description = "Ruby SOAP client library to enjoy."
  s.homepage = "http://github.com/smacks/savon"
  s.summary = "Ruby SOAP client library to enjoy."

  s.has_rdoc = true
  s.rdoc_options = ["--inline-source", "--charset=UTF-8"]
  s.extra_rdoc_files = ["README.rdoc"]
  s.files = [
    "README.rdoc", "lib/savon.rb", "lib/savon/service.rb",
    "lib/savon/wsdl.rb", "lib/savon/response.rb", ]
  s.test_files = [
    "test/test_savon.rb","test/helper.rb", "test/factories/wsdl.rb",
    "test/fixtures/soap_response_fixture.rb", "test/savon/test_service.rb",
    "test/savon/test_response.rb", "test/savon/test_wsdl.rb"]

  s.requirements << 'mocha and shoulda for testing'

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new("1.2.0") then
      s.add_runtime_dependency("hpricot", "0.6.164")
      s.add_runtime_dependency("smacks-apricoteatsgorilla", ">= 0.4.5")
    else
      s.add_dependency("hpricot", "0.6.164")
      s.add_dependency("smacks-apricoteatsgorilla", ">= 0.4.5")
    end
  else
    s.add_dependency("hpricot", "0.6.164")
    s.add_dependency("smacks-apricoteatsgorilla", ">= 0.4.5")
  end
end