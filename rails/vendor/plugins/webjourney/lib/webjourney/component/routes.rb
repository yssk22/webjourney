module WebJourney  # :nodoc:
  module Component # :nodoc:
    class Routes   # :nodoc:
      def self.mapper
        @@mapper
      end

      def self.mapper=(mapper)
        @@mapper = mapper
      end

      def self.draw
        yield @@mapper
      end
    end
  end
end

