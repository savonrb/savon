class Savon
  class XML
    class Attribute

      attr_accessor :name, :base_type, :use

      def optional?
        use == 'optional'
      end

    end
  end
end
