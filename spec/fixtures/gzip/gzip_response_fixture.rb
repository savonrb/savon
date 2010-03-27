class GzipResponseFixture

  def self.message
    File.read(File.join(File.dirname(__FILE__), 'message.gz'))
  end
end

