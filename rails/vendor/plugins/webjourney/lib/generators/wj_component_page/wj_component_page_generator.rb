require 'yaml'
class WjComponentPageGenerator < Rails::Generator::NamedBase
  attr_accessor :component_name, :page_name, :display_name, :permissions, :yaml_string
  include WebJourney::Component::Path

  def initialize(*args)
    super
    gen_args = args.first
    # parsing gen_args
    name = args[0].shift
    unless name =~ /^([a-z][a-z_0-9]*)\/([a-z][a-z_0-9]*)$/
      return usage
    end
    @component_name = $1
    @page_name    = $2

    # all args except first argument should be <name>=<value>
    # name is [a-z]+
    hash = {}
    names = %w(permissions)
    gen_args.each do |argument|
      if argument =~ /([a-z_0-9]+)\=(.+)/
        if $1 == "permissions"
          hash[$1] = $2.split(",")
        else
          hash[$1] = $2
        end
      else
        puts "arguments should be [#{names.join('|')}]=<value>"
        return usage
      end
    end
    @permissions = hash.delete("permissions")
  end

  def manifest
    record do |m|
      # directories to be created
      DIRECTORIES_IN_COMPONENTS.each do |key, path|
        m.directory File.join("components", component_name, path)
      end
      m.directory File.join("components", component_name, page_name)

      m.template("controller", File.join("components", component_name, "#{page_name}_controller.rb"))


      # add or update YAML file entry
      yamlfile = File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["definitions"], "wj_component_pages.yml")
      config = { @page_name => {
          "display_name"  => @page_name.titleize
        }}
      config[:parameters] = @paramters if @parameters
      current = nil

      if File.exists?(yamlfile)
        current = YAML.load_file(yamlfile)
      else
        current = []
      end
      unless current.select { |page| page.keys.first == @page_name }.length > 0
        current << config
        @yaml_string = YAML.dump(current)
        m.template("wj_component_pages", yamlfile)
      end
    end
  end
end
