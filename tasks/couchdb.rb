namespace :couchdb do
  desc("Configure CouchDB for WebJourney")
  task :configure do
    puts "Set authentication (cookie enabled)."
    RelaxClient.set_server_config("httpd/authentication_handlers",
                                  "{couch_httpd_auth, cookie_authentication_handler}, {couch_httpd_auth, default_authentication_handler}")
    Rake::Task["couchdb:restart"].invoke
  end

  task :restart do
    result = RelaxClient.restart
    if result["ok"]
      puts "CouchDB restarted."
    else
      raise result["reason"]
    end
  end
end
