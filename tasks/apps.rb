require 'rexml/document'
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
      webjourney =
      APP_TO_DB.each do |app_name, db_uri|
        dir = app_dir(app_name)

        # Deploy CouchApp
        step("Push #{app_name} application.") do
          sh("couchapp push #{dir} #{db_uri}")
        end

        # Register WebJourney Application Directory
        db  = RelaxClient.for_container("webjourney")
        step("Register #{app_name} application on WebJourney Application Collection.") do
          # app_doc = JSON(File.read(File.join(dir, "couchapp.json")))
          doc_id  = "app:#{app_name}"
          app_doc = {
            "_id"  => doc_id,
            "type" => "Application"
          }
          app_doc["_id"]  = doc_id
          app_doc["type"] = "Application"
          # TODO Register the internal xml URI must be insecure!!
          # This should be fixed to register the external XML URI.
          app_doc["gadget_xml"] = File.join(db_uri, "_design", app_name, "gadget.xml")

          # copy metadata in xml definition.
          app_xml      = REXML::Document.new(File.read(File.join(dir, "_attachments/gadget.xml")))
          module_prefs = REXML::XPath.first(app_xml, "//Module/ModulePrefs")
          # ModulePref
          module_prefs_doc = { "_attrs" => {} }
          %w(title title_url description author author_email category).each do |attr|
            module_prefs_doc["_attrs"][attr] = module_prefs.attributes[attr]
          end
          app_doc["module_prefs"] = module_prefs_doc
          # TODO UserPref
          old_doc = db.load(doc_id) rescue {}
          new_doc = old_doc.update(app_doc)
          db.save(new_doc)
          puts "Gadget XML: #{app_doc['gadget_xml']}"
        end
      end
   end
  end
end
