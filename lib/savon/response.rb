require "nori"

class Savon
  class Response

    def initialize(raw_response)
      @raw_response = raw_response
    end

    def raw
      @raw_response
    end

    def body
      hash[:envelope][:body]
    end
    alias to_hash body

    def hash
      @hash ||= nori.parse(raw)
    end

    def doc
      @doc ||= Nokogiri.XML(raw)
    end

    def xpath(path, namespaces = nil)
      doc.xpath(path, namespaces || xml_namespaces)
    end

    private

    def nori
      return @nori if @nori

      nori_options = {
        :strip_namespaces => true,
        :convert_tags_to  => -> (tag) { tag.snakecase.to_sym }
      }

      non_nil_nori_options = nori_options.reject { |_, value| value.nil? }
      @nori = Nori.new(non_nil_nori_options)
    end

  end
end
