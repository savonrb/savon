class Wasabi
  class Param

    def initialize(namespace, local)
      @namespace = namespace
      @local = local
    end

    attr_reader :namespace, :local

  end
end
