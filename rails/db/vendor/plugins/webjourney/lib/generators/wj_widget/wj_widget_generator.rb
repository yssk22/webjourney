require 'yaml'
class WjWidgetGenerator < Rails::Generator::NamedBase
  attr_accessor :component_name, :widget_name, :yaml_string
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
    @widget_name    = $2

    # all args except first argument should be <name>=<value>
    # name is [a-z]+
    hash = {}
    names = %w(display_name with_boxing)
    gen_args.each do |argument|
      if argument =~ /([a-z_0-9]+)\=(.+)/
        hash[$1] = $2
      else
        puts "arguments should be [#{names.join('|')}]=<value>"
        return usage
      end
    end
  end

  def manifest
    record do |m|
      # directories to be created
      DIRECTORIES_IN_COMPONENTS.each do |key, path|
        m.directory File.join("components", component_name, path)
      end
      # view directory
      m.directory File.join("components", component_name, widget_name)

      # first migration file
      m.template("controller", File.join("components", component_name, "#{widget_name}_controller.rb"))
      m.template("show",       File.join("components", component_name, widget_name,  "show.html.erb"))
      m.template("edit",       File.join("components", component_name, widget_name,  "edit.html.erb"))
      m.template("widget.png", File.join("public/components", component_name, DIRECTORIES_IN_PUBLIC["images"], "#{widget_name}.png"))

      # add or update YAML file entry
      yamlfile = File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["definitions"],  "wj_widgets.yml")
      config = {@widget_name => {
          "display_name" => @widget_name.titleize
        }}
      current = nil

      if File.exists?(yamlfile)
        current = YAML.load_file(yamlfile)
        puts "wj_widgets.yml file already exists"
        unless current.select { |widget| widget.keys.first == @widget_name }.length > 0
          current << config
        end
      else
        current = [config]
      end
      @yaml_string = YAML.dump(current)
      m.template("wj_widgets", yamlfile)
    end
  end
end
