namespace :all do
  desc("Initialize All components")
  task :initialize do
    Rake::Task["containers:initialize"].invoke
    Rake::Task["gadgets:initialize"].invoke
    step("WebJourney has been initialized successfully.") do
      uri = URI.parse(RelaxClient.for_container("webjourney").uri)
      uri = "#{uri.scheme}://#{uri.host}#{uri.path}/_design/webjourney/_show/top"

      puts "Visit your webjourney here:"
      puts ""
      puts "   #{uri}"
      puts ""
    end
  end
end
