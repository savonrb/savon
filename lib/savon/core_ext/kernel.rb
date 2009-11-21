module Kernel

  # Returns the global Savon::Config.
  def savon_config
    Savon::Config.instance
  end

end
