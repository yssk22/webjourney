class WjResourcesGenerator < Rails::Generator::NamedBase # :nodoc:
  attr_accessor :component_name, :resources_name
  include WebJourney::Component::Task::Package::Path

  def initialize(*args)
    super
    gen_args = args.first
    # parsing gen_args
    name = args[0].shift
    unless name =~ /^([a-z][a-z_0-9]*)\/([a-z][a-z_0-9]*)$/
      return usage
    end
    @component_name = $1
    @resources_name = $2
  end

  def manifest
    record do |m|
      # directories to be created
      DIRECTORIES_IN_COMPONENTS.each do |key, path|
        m.directory File.join("components", component_name, path)
      end
      # view directory
      m.directory File.join("components", component_name, resources_name)

      # first migration file
      m.template("controller", File.join("components", component_name, "#{resources_name}_controller.rb"))
    end
  end
end
