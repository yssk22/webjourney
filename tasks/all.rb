namespace :all do
  desc("Initialize All components")
  task :initialize do
    Rake::Task["couchdb:configure"].invoke
    Rake::Task["containers:initialize"].invoke
    Rake::Task["gadgets:initialize"].invoke
    step("WebJourney has been initialized successfully.") do
      uri = URI.parse(RelaxClient.for_container("webjourney").uri)
      uri = "#{uri.scheme}://#{uri.host}#{uri.path}/_design/webjourney/_show/page/top"

      puts "Visit your webjourney here:"
      puts ""
      puts "   #{uri}"
      puts "   -- You can log in the site with wj_admin/password."
    end
  end
end
