class CreateWjComponentPages < ActiveRecord::Migration
  def self.up
    create_table :wj_component_pages do |t|
      t.integer :wj_component_id,               :null => false, :default => nil
      t.integer :menu_order,                    :null => false, :default => 1
      t.string  :controller_name, :limit => 64, :null => false, :default => nil
      t.string  :display_name,    :limit => 64, :null => false, :default => nil
      t.timestamps
    end
    add_index :wj_component_pages, [:controller_name], :name => :wj_component_pages_controller_name
    add_index :wj_component_pages, [:wj_component_id], :name => :wj_component_pages_wj_component_id
  end

  def self.down
    drop_table :wj_component_pages
  end
end
