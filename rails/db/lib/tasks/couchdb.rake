require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
namespace :couchdb do
  require File.dirname(__FILE__) + '/../../config/boot'
  require File.dirname(__FILE__) + '/../../config/environment'
  def create_db(env, target)
    uri    = URI.parse(CouchConfig.database_uri_for(:db => target, :env => env))
    Net::HTTP.start(uri.host, uri.port) do |http|
      if http.get(uri.path).is_a?(Net::HTTPOK)
        puts "[Skip] The database '#{uri}' already exists."
      else
        res = http.put(uri.path, nil)
        if res.is_a?(Net::HTTPCreated)
          puts "[Create] Create a database on '#{uri}'."
        else
          res.error!
        end
      end
    end
  end

  def drop_db(env, target)
    uri    = URI.parse(CouchConfig.database_uri_for(:db => target, :env => env))
    Net::HTTP.start(uri.host, uri.port) do |http|
      if http.get(uri.path).is_a?(Net::HTTPNotFound)
        puts "[Skip] The database '#{uri}' does not exist."
      else
        res = http.delete(uri.path)
        if res.is_a?(Net::HTTPOK)
          puts "[Drop] Drop a database on '#{uri}'."
        else
          res.error!
        end
      end
    end
  end

  desc("Create couchdb's databases used for the current environment")
  task :create do
    CouchConfig.get()[RAILS_ENV].each do |target, config|
      create_db(RAILS_ENV, target)
    end
  end

  namespace :create do
  desc("Create couchdb's databases used for the all environments")
    task :all do
      CouchConfig.get().each do |env, config|
        config.each do |target, config2|
          create_db(env, target)
        end
      end
    end
  end

  desc("Drop couchdb's databases used for the current environment")
  task :drop do
    CouchConfig.get()[RAILS_ENV].each do |target, config|
      drop_db(RAILS_ENV, target)
    end
  end

  namespace :drop do
    desc("Drop couchdb's databases used for the all environments")
    task :all do
      CouchConfig.get().each do |env, config|
        config.each do |target, config2|
          drop_db(env, target)
        end
      end
    end
  end

  namespace :fixtures do
    task :load do
      CouchFixture.load
    end
  end
end
