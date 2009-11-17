# container and db mappping
CONTAINER_TO_DB  = RelaxClient.config["containers"]
DB_TO_CONTAINERS = {}
CONTAINER_TO_DB.each do |container, db_name|
  DB_TO_CONTAINERS[db_name] = (DB_TO_CONTAINERS[db_name] || []) << container
end

namespace :containers do
  desc("Initialize WebJourney Site")
  task :initialize do
    Rake::Task["containers:initialize:db"].invoke
    Rake::Task["containers:initialize:app"].invoke
  end

  namespace :initialize do
    desc("Initialize container databases.")
    task :db do
      DB_TO_CONTAINERS.each do |db_name, container_names|
        db = RelaxClient.for_container(container_names.first)
        init_database(db)
      end
      CONTAINER_TO_DB.each do |container_name, db_name|
        db = RelaxClient.for_container(container_name)
        dir = container_dir(container_name)
        import_dataset(db, dir)
      end
    end

    desc("Initialize container applications")
    task :app do
      CONTAINER_TO_DB.each do |container_name, db_name|
        dir = container_dir(container_name)
        db = RelaxClient.for_container(container_name).uri
        step("Push the application") do
          sh("couchapp push #{dir} #{db}")
        end
      end
    end
  end
end



