# Enabling Component routing class
module WebJourney
  module Routing
    class ComponentRoutes
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

