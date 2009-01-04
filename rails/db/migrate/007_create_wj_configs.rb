class CreateWjConfigs < ActiveRecord::Migration
  def self.up
    create_table :wj_configs do |t|
      # design configuration
      t.column "design_theme",              :string,  :limit =>  64, :null => false, :default => "default"
      t.column "design_width",              :integer,                :null => false, :default => 800
      t.column "design_width_unit",         :string,  :limit =>  3,  :null => false, :default => "px"
      t.column "design_lwidth",             :integer, :limit =>  10, :null => false, :default => 200
      t.column "design_lwidth_unit",        :string,  :limit =>   3, :null => false, :default => "px"
      t.column "design_rwidth",             :integer, :limit =>  10, :null => false, :default => 200
      t.column "design_rwidth_unit",        :string,  :limit =>   3, :null => false, :default => "px"
      # site page settings
      t.column "site_title",              :string,  :limit =>  64, :null => false, :default => "WebJourney::Widgets on Rails"
      t.column "site_robots_index",       :boolean,  :null => false, :default => true
      t.column "site_robots_follow",      :boolean,  :null => false, :default => true
      t.column "site_keywords",           :string,  :limit => 255, :null => false, :default => "ruby,rails,ruby on rails,ror,web journey"
      t.column "site_description",        :string,  :limit => 255, :null => false # :default => "site powered by WebJourney::Widgets on Rails"
      t.column "site_copyright",          :string,  :limit => 128, :null => false, :default => ""
      # SMTP settings
      t.column "smtp_address",       :string,  :limit => 255, :null => false, :default => "localhost"
      t.column "smtp_domain",        :string,  :limit => 255, :null => true,  :default => "localhost"
      t.column "smtp_port",          :integer,                :null => false, :default => 25
      t.column "smtp_user_name",     :string,  :limit => 255, :null => true,  :default => nil
      t.column "smtp_password",      :string,  :limit => 255, :null => true,  :default => nil
      t.column "smtp_authentication",:string,  :limit =>  20, :null => true,  :default => nil
      # account
      t.column "account_allow_local_db_register", :boolean, :null => false, :default => true
      t.column "account_allow_open_id_register", :boolean, :null => false, :default => true
      t.timestamps
    end
  end

  def self.down
    drop_table :wj_configs
  end
end
