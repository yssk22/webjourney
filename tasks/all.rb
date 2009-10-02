namespace :all do
  desc("Initialize All components")
  task :initialize do
    Rake::Task["containers:initialize"].invoke
    Rake::Task["apps:initialize"].invoke
    step("WebJourney has been initialized successfully.") do
      puts "Visit your webjourney here:"
      puts
      puts "   #{HTTP_ROOT}/#{TOP_PAGE_PATH}"
      puts
    end
  end
end
