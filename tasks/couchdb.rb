namespace :couchdb do
  desc("Configure CouchDB for WebJourney")
  task :configure do
    puts "Set authentication (cookie enabled)."
    RelaxClient.set_server_config("httpd/authentication_handlers",
                                  "{couch_httpd_auth, cookie_authentication_handler}, {couch_httpd_oauth, oauth_authentication_handler}, {couch_httpd_auth, default_authentication_handler}")
    RelaxClient.set_server_config("couch_httpd_auth/secret",
                                  "webjourney")
    RelaxClient.set_server_config("couch_httpd_auth/authentication_db",
                                  "webjourney-accounts-default")
    RelaxClient.set_server_config("couch_httpd_auth/timeout",
                                  (RelaxClient.config["couchdb"]["session_timeout"] || 3600).to_s)
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
