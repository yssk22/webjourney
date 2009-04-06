require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

namespace :wj do
  Rake::RDocTask.new("doc") { |rdoc|
    rdoc.rdoc_dir = 'doc'
    rdoc.title    = "WebJourney API Reference"
    rdoc.options << '--line-numbers' << '--inline-source'
    rdoc.rdoc_files.include('README')
    rdoc.rdoc_files.include('app/**/*.rb')
    rdoc.rdoc_files.include('lib/**/*.rb')
    rdoc.rdoc_files.include('vendor/plugins/couch_resource/**/*.rb')
    rdoc.rdoc_files.include('vendor/plugins/webjourney/**/*.rb')
    rdoc.template = "jamis"
  }

  namespace :doc do
    task :update do
      Rake::Task["wj:doc"].invoke
      sh "rsync -avze ssh doc/ www:~/sitedoc/webjourney/"
    end
  end
end
