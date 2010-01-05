require "webrick"

include WEBrick

# Run WEBrick. Yields the server to a given block.
def run_webrick(config = {})
  config.update :Port => 8080
  server = HTTPServer.new config
  yield server if block_given?
  ["INT", "TERM"].each { |signal| trap(signal) { server.shutdown } }
  server.start
end

# Returns the SOAP response fixture for a given +file+.
def respond_with(file)
  response_path = File.dirname(__FILE__) + "/../fixtures/response/xml"
  File.read "#{response_path}/#{file}.xml"
end

# Returns HTML links for a given Hash of link URI's and names.
def link_to(links)
  links.map { |link| "<a href='#{link[:uri]}'>#{link[:name]}</a>" }.join("<br>")
end

run_webrick do |server|
  user, password, realm = "user", "password", "realm"

  htdigest = HTTPAuth::Htdigest.new "/tmp/webrick-htdigest"
  htdigest.set_passwd realm, user, password
  authenticator = HTTPAuth::DigestAuth.new :UserDB => htdigest, :Realm => realm

  # Homepage including links to subpages.
  server.mount_proc("/") do |request, response|
    response.body = link_to [
      { :uri => "http-basic-auth", :name => "HTTP basic auth" },
      { :uri => "http-digest-auth", :name => "HTTP digest auth" }
    ]
  end

  # HTTP basic authentication.
  server.mount_proc("/http-basic-auth") do |request, response|
    HTTPAuth.basic_auth(request, response, realm) { |u, p| u == user && p == password }
    response.body = respond_with :authentication
  end

  # HTTP digest authentication.
  server.mount_proc("/http-digest-auth") do |request, response|
    authenticator.authenticate request, response
    response.body = "HTTP digest authentication successfull"
  end
end
