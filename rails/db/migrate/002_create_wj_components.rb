class CreateWjComponents < ActiveRecord::Migration
  def self.up
    create_table :wj_components do |t|
      t.string :directory_name,   :limit => 64,  :null => false, :default => nil
      t.string :display_name,     :limit => 64,  :null => false, :default => nil
      t.string :description,      :limit => 255, :null => false, :default => ""
      t.integer :version,                        :null => false, :default => 1
      t.string :license,          :limit => 8,   :null => true,  :default => nil
      t.string :url,              :limit => 255, :null => true,  :default => nil
      t.string :author,           :limit => 64,  :null => true,  :default => nil
      t.timestamps
    end
    add_index :wj_components, [:directory_name], :name => :wj_components_directory_name
  end

  def self.down
    drop_table :wj_components
  end
end
