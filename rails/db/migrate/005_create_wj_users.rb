class CreateWjUsers < ActiveRecord::Migration
  def self.up
    create_table :wj_users do |t|
      t.string   :login_name,   :limit => 16, :null => false, :default => nil
      t.string   :display_name, :limit => 32, :null => true,  :default => nil
      t.datetime :last_login_at,              :null => true,  :default => nil
      t.integer  :status,                     :null => true,  :default => nil
      t.string   :type,         :limit => 32, :null => false, :default => nil

      # for notification
      t.string   :email,         :limit => 255, :null => true, :default => nil

      # for WjUser::Local
      t.string   :password_hash,    :limit => 32,  :null => true, :default => nil
      t.string   :request_passcode, :limit => 128, :null => true, :default => nil
      t.string   :request_key,      :limit => 32,  :null => true, :default => nil
      t.string   :request_value,    :limit => 255, :null => true, :default => nil
      t.datetime :request_at,                      :null => true, :default => nil

      # for WjUser::OpenId
      t.string   :open_id_uri,           :limit => 255, :null => true, :default => nil

      t.timestamps
    end
    add_index :wj_users,  [:login_name], :name => :wj_users_login_name, :unique => true
    add_index :wj_users,  [:email],      :name => :wj_users_email,      :unique => false
  end

  def self.down
    drop_table :wj_users
  end
end
