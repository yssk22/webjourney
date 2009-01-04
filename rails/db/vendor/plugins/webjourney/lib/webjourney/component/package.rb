module WebJourney
  module Component
    class Package
      attr_accessor :component_name
      def initialize(component_name)
        raise ArgumentError.new("'component_name' shoud be _^[a-z][a-z0-9_]*$/") unless component_name =~ /^[a-z][a-z0-9_]*$/
        @component_name = component_name
        @output = $stdout
      end

      # install component
      def install(deploy = false)
        copy_to_deployed if deploy
        register
        migrate
      end

      # install component
      def uninstall(undeploy = false)
        migrate 0
        unregister
        cleanup_deployed if undeploy
      end

      def puts(msg)
        @output.puts(msg) if @output.respond_to?(:puts)
      end

      def set_output(output)
        @output = output
      end
    end
  end
end
