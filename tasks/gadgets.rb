require 'rexml/document'
APP_TO_DB = RelaxClient.config["gadgets"]
DB_TO_APPS = {}
APP_TO_DB.each do |app, db_name|
  DB_TO_APPS[db_name] = (DB_TO_APPS[db_name] || []) << app
end

namespace :gadgets do
  desc("Initialize OpenSocial Applications")
  task :initialize do
    Rake::Task["gadgets:initialize:db"].invoke
    Rake::Task["gadgets:initialize:app"].invoke
  end

  desc("Generate a new OpenSocial application directory")
  task :generate do
    name = ENV["NAME"]
    puts "NAME={app_name} should be specified." if blank?(name)
    target = gadget_dir(name)
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
      DB_TO_APPS.each do |db_name, app_names|
        db = RelaxClient.for_gadget(app_names.first)
        init_database(db)
      end
      APP_TO_DB.each do |app_name, db_name|
        db = RelaxClient.for_gadget(app_name)
        dir = gadget_dir(app_name)
        import_dataset(db, File.join(File.dirname(__FILE__), "../config/install/container", app_name))
      end
    end

    desc("Initialize OpenSocial applications")
    task :app do
      webjourney =
      APP_TO_DB.each do |app_name, db_name|
        dir = gadget_dir(app_name)
        db  = RelaxClient.for_gadget(app_name)
        # Deploy CouchApp
        step("Push #{app_name} application.") do
          couchapp_push(dir, db.uri)
        end

        # Register WebJourney Application Directory
        db  = RelaxClient.for_container("webjourney")
        step("Register #{app_name} application on WebJourney Application Collection.") do
          couchapp = JSON(File.read(File.join(dir, "couchapp.json")))
          couchapp["gadgets"].each do |gadget|
            gadget_title = gadget["title"]
            doc_id  = "app:#{app_name}:#{gadget_title}"
            app_doc = {
              "_id"  => doc_id,
              "type" => "Application"
            }
            # TODO Register the internal xml URI must be insecure!!
            # This should be fixed to register the external XML URI.
            app_doc["gadget_xml"] = File.join(db.uri, "_design", app_name, gadget["xml"])
            # ModulePref
            module_prefs_doc = { "_attrs" => {} }
            %w(title title_url description author author_email category).each do |attr|
              module_prefs_doc["_attrs"][attr] = gadget[attr] || couchapp[attr]
            end
            # TODO UserPref
            app_doc["module_prefs"] = module_prefs_doc
            old_doc = db.load(doc_id) rescue {}
            new_doc = old_doc.update(app_doc)
            db.save(new_doc)
            puts "Gadget XML: #{app_doc['gadget_xml']}"
          end
        end
      end
   end
  end
end
