namespace :accounts do
  namespace :wj_admin do  
    desc("Initialize the administrator account")
    task :initialize do
      result = RelaxClient.create_user("wj_admin", "password",
                                       :roles => ["wj_admin"])
      if result["ok"]
        puts "The administrator account has been created."
      else
        result = RelaxClient.update_user("wj_admin", "password",
                                         :roles => ["wj_admin"])
        if result["ok"]
          puts "The administrator account has been updated."
        else
          raise "Unknown error! - #{result.to_json}"
        end
      end
    end

    desc("Set the password for Site Administrator")
    task :set_password do
      raise "Not Implemented."
    end

    desc("Set the email for Site Administrator") 
    task :set_email do
      raise "Not Implemented."
    end
  end
end
