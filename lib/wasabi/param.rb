class Wasabi
  class Param

    def initialize(nsid, local)
      @nsid = nsid
      @local = local
    end

    attr_reader :nsid, :local

    def singular?
      true
    end

    def tag
      [@nsid, @local.to_sym].compact
    end

  end
end
