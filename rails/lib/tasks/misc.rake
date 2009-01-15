require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require File.dirname(__FILE__) + '/../../config/boot'
require File.dirname(__FILE__) + '/../../config/environment'
include RakeUtil

YUICOMPRESSOR = File.join(RAILS_ROOT, "vendor/tools/yuicompressor-2.4.2/build/yuicompressor-2.4.2.jar")
JS_TEMPLATE   = File.join(RAILS_ROOT, "app/views/share/javascripts.html.erb")
CSS_TEMPLATE  = File.join(RAILS_ROOT, "app/views/share/stylesheets.html.erb")
JSL_CONFIG    = File.join(RAILS_ROOT, "config/jsl.conf")

def js_fullpath(src)
  unless src =~ /\.js$/
    src = src + ".js"
  end
  if src =~ /^\//
    File.join(RAILS_ROOT, "public", src)
  else
    File.join(RAILS_ROOT, "public", "javascripts", src)
  end
end

namespace :misc do
  namespace :js do
    desc("Execute JavaScript Lint")
    task :lint do
      command = "jsl -conf #{JSL_CONFIG} +recurse"
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
          if name == :javascript_include_tag
            option = sources.extract_options!
            if option[:cache]
              cachepath = js_fullpath((option[:cache] == true ? "all" : option[:cache]))
              puts "Generate cache on #{cachepath}"
              # concat source files
              File.open(cachepath, "w") do |f|
                sources.each do |src|
                  f.puts("// --- from #{src}")
                  f.write(File.read(js_fullpath(src)))
                end
              end
              # compresser
              command = "java -jar #{YUICOMPRESSOR} --type js -o #{cachepath} #{cachepath}"
              puts "Executing YUI Compressor ..."
              sh(command)
            end
          end
        end
        view = ERB.new(File.read(JS_TEMPLATE))
        view.result(binding)
      end

      desc("Clear compressed javascript caches for the production environment.")
      task :clear do
        def method_missing(name, *sources)
          if name == :javascript_include_tag
            option = sources.extract_options!
            if option[:cache]
              cachepath = js_fullpath(option[:cache] == true ? "all" : option[:cache])
              puts "Clear cache from #{cachepath}"
              File.delete(cachepath)
            end
          end
        end
        view = ERB.new(File.read(JS_TEMPLATE))
        view.result(binding)
      end
    end
  end
end
