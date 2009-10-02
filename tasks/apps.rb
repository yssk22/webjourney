APP_TO_DB = RelaxClient.config["apps"]
DB_TO_APPS = {}
APP_TO_DB.each do |app, db_uri|
  DB_TO_APPS[db_uri] = (DB_TO_APPS[db_uri] || []) << app
end

namespace :apps do
  desc("Initialize OpenSocial Applications")
  task :initialize do
    Rake::Task["apps:initialize:db"].invoke
    Rake::Task["apps:initialize:app"].invoke
  end

  desc("Generate a new OpenSocial application directory")
  task :generate do
    name = ENV["NAME"]
    puts "NAME={app_name} should be specified." if blank?(name)
    target = app_dir(name)
    app = {
      "name" => name,
      "description" => "Your application description"
    }

    # couchapp generation
    if File.exist?(target)
      puts "[INFO] couchapp generation was skipped."
    else
      sh("couchapp generate #{target}")
    end

    # gadget xml generation
    xml_path      = File.join(target, "_attachments/gadget.xml")
    if File.exist?(xml_path)
      puts "[INFO] gadget xml generation was skipped."
    else
      xml_template  = dir("config/gadget.template.xml")
      xml = ERB.new(File.read(xml_template), nil, '-').result(binding)
      File.open(xml_path, "w") do |f|
        f.write(xml)
      end
      puts "[INFO] Generating a gadget xml file on #{xml_path}."
    end
  end

  namespace :initialize do
    desc("Initialize OpenSocial application databases")
    task :db do
      DB_TO_APPS.each do |db_uri, app_names|
        db = RelaxClient.for_app(app_names.first)
        init_database(db)
      end
      APP_TO_DB.each do |app_name, db_uri|
        db = RelaxClient.for_app(app_name)
        dir = app_dir(app_name)
        import_dataset(db, dir)
      end
    end

    desc("Initialize OpenSocial applications")
    task :app do
      APP_TO_DB.each do |key, db|
        dir = app_dir(key)
        step("Push the application") do
          sh("couchapp push #{dir} #{db}")
        end
      end
   end
  end

end
