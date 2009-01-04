class CreateWjRoles < ActiveRecord::Migration
  def self.up
    create_table :wj_roles do |t|
      t.string  :name, :limit => 32, :null => false, :default => nil
      t.boolean :is_default,         :null => false, :default => false
      t.string  :type, :limit => 32, :null => false, :default => nil
      t.timestamps
    end
    add_index :wj_roles,  [:name],      :name => :wj_roles_name, :unique => true

    # habtm table
    create_table(:wj_roles_wj_users, :id => false) do |t|
      t.integer :wj_role_id,  :null => false, :default => nil
      t.integer :wj_user_id,  :null => false, :default => nil
    end
    add_index :wj_roles_wj_users, [:wj_user_id, :wj_role_id], :unique => true
  end

  def self.down
    drop_table :wj_roles
    drop_table :wj_roles_wj_users
  end
end
