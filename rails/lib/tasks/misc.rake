require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.dirname(__FILE__) + '/../../config/boot'
require File.dirname(__FILE__) + '/../../config/environment'
include RakeUtil

YUICOMPRESSOR  = File.join(RAILS_ROOT, "vendor/tools/yuicompressor-2.4.2/build/yuicompressor-2.4.2.jar")
JS_TEMPLATE    = File.join(RAILS_ROOT, "app/views/share/javascripts.html.erb")
CSS_TEMPLATE   = File.join(RAILS_ROOT, "app/views/share/stylesheets.html.erb")
JSL_CONFIG     = File.join(RAILS_ROOT, "config/jsl.conf")
TMP_JSL_CONFIG = File.join(RAILS_ROOT, "tmp/webjourney/.jsl.conf")

def js_fullpath(src)
  public_fullpath(src, "javascripts", ".js")
end

def css_fullpath(src)
  public_fullpath(src, "stylesheets", ".css")
end

def public_fullpath(src, prefix, suffix)
  unless src =~ /#{suffix}$/
    src = src + suffix
  end
  if src =~ /^\//
    File.join(RAILS_ROOT, "public", src)
  else
    File.join(RAILS_ROOT, "public", prefix, src)
  end
end

def generate_cache(type, *sources)
  option = sources.extract_options!
  if option[:cache]
    cachepath = send("#{type}_fullpath", (option[:cache] == true ? "all" : option[:cache]))
    puts "Generate cache on #{cachepath}"
    # concat source files
    File.open(cachepath, "w") do |f|
      sources.each do |src|
        f.puts("/** from #{src} **/")
        f.write(File.read(send("#{type}_fullpath", src)))
      end
    end
    # compresser
    command = "java -jar #{YUICOMPRESSOR} --type #{type} -o #{cachepath} #{cachepath}"
    puts "Executing YUI Compressor ..."
    sh(command)
  end
end

def clear_cache(type, *sources)
  option = sources.extract_options!
  if option[:cache]
    cachepath = send("#{type}_fullpath", (option[:cache] == true ? "all" : option[:cache]))
    puts "Clear cache from #{cachepath}"
    File.delete(cachepath)
  end
end

namespace :misc do
  namespace :cache do
    task :generate do
      Rake::Task["misc:js:cache:generate"].invoke
      Rake::Task["misc:css:cache:generate"].invoke
    end
    task :clear do
      Rake::Task["misc:js:cache:clear"].invoke
      Rake::Task["misc:css:cache:clear"].invoke
    end
  end
  namespace :js do
    desc("Execute JavaScript Lint")
    task :lint do
      targets = if ENV["COMPONENT"]
                  File.join(RAILS_ROOT, "public/components", ENV["COMPONENT"], "javascripts/*.js")
                else
                  File.join(RAILS_ROOT, "public/javascripts/webjourney/*.js")
                end
      File.open(TMP_JSL_CONFIG, "w") do |f|
        f.puts File.read(JSL_CONFIG)
        f.puts "+process " + targets
      end
      # make a temporary configuration
      command = "jsl -conf #{TMP_JSL_CONFIG} +recurse"
      begin
        sh(command)
      rescue => e
        puts e.inspect
      end
    end

    namespace :cache do
      desc("Generate compressed javascript caches for the production environment.")
      task :generate do
        def method_missing(name, *sources)
            generate_cache("js", *sources) if name == :javascript_include_tag
        end
        view = ERB.new(File.read(JS_TEMPLATE))
        view.result(binding)
      end

      desc("Clear compressed javascript caches for the production environment.")
      task :clear do
        def method_missing(name, *sources)
          clear_cache("js", *sources) if name == :javascript_include_tag
        end
        view = ERB.new(File.read(JS_TEMPLATE))
        view.result(binding)
      end
    end
  end

  namespace :css do
    namespace :cache do
      desc("Generate compressed stylesheet caches for the production environment.")
      task :generate do
        def method_missing(name, *sources)
          generate_cache("css", *sources) if name == :stylesheet_link_tag
        end
        view = ERB.new(File.read(CSS_TEMPLATE))
        view.result(binding)
      end

      desc("Clear compressed stylesheet caches for the production environment.")
      task :clear do
        def method_missing(name, *sources)
          clear_cache("css", *sources) if name == :stylesheet_link_tag
        end
        view = ERB.new(File.read(CSS_TEMPLATE))
        view.result(binding)
      end
    end
  end
end
