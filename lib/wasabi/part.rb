class Wasabi

  class Part

    def initialize(name, qname)
      @name = name
      @qname = qname

      @local, @nsid = qname.split(':').reverse
    end

    attr_reader :name, :nsid, :local

  end

  class TypePart < Part; end
  class ElementPart < Part; end

end
