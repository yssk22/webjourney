class CreateWjWidgets < ActiveRecord::Migration
  def self.up
    create_table :wj_widgets do |t|
      t.integer :wj_component_id,               :null => false, :default => nil
      t.integer :menu_order,                    :null => false, :default => 1
      t.string :controller_name, :limit => 64,  :null => false, :default => nil
      t.string :display_name,    :limit => 64,  :null => false, :default => nil
      t.text   :parameters,                     :null => true,  :default => nil
      t.timestamps
    end
    add_index :wj_widgets, [:wj_component_id],    :name => :wj_widgets_wj_component_id
    add_index :wj_widgets, [:controller_name],    :name => :wj_widgets_wj_controller_name
  end

  def self.down
    drop_table :wj_widgets
  end
end
