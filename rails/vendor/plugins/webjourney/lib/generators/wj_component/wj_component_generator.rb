class WjComponentGenerator < Rails::Generator::NamedBase
  attr_accessor :component_name, :license, :url, :author, :description
  include WebJourney::Component::Path

  def initialize(*args)
    super
    gen_args = args.first
    # parsing gen_args
    @component_name = args[0].shift
    unless @component_name =~ /^[a-z][a-z_0-9]*$/
      puts "component name charactor must be /^[a-z][a-z_0-9]*$/ (starts with alphabetic lower characters, and sequence of alphabetic(a-z), underscore('_') or number(0-9)."
      return usage
    end
    # all args except first argument should be <name>=<value>
    # name is [a-z]+
    hash = {}
    names = %w(license url author description)
    gen_args.each do |argument|
      if argument =~ /([a-z]+)\=(.+)/
        hash[$1] = $2
      else
        puts "arguments should be [#{names.join('|')}]=<value>"
        return usage
      end
    end
    @license     = hash.delete("license")     || "MIT"
    @author      = hash.delete("author")      || %x(whoami).gsub("\n", '') rescue "unknon"  # whoami failed
    @url         = hash.delete("url")         || nil
  end

  def manifest
    record do |m|
      DIRECTORIES_IN_COMPONENTS.each do |key, path|
        m.directory File.join("components", component_name, path)
      end

      # directories to be created
      DIRECTORIES_IN_PUBLIC.each do |key, path|
        m.directory File.join("public/components", component_name, path)
      end

      # files to be created
      m.template "wj_component",
      File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["definitions"], "wj_component.yml")

      # first migration file
      # not use migrate_template method
      m.template "migration",
      File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["migrations"], "001_#{component_name}_install.rb")

      # routing file
      m.template "routes",
      File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["configurations"], "routes.rb")

      # couchdb file
      m.template "couchdb",
      File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["configurations"], "couchdb.yml")

      # test files
      m.directory File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["fixtures"], component_name)
      m.template "test_helper",
      File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["test"], "test_helper.rb")
      m.template "functional_helper",
      File.join("components", component_name, DIRECTORIES_IN_COMPONENTS["test"], "functional_helper.rb")
    end
  end
end
