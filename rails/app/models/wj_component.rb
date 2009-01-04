class WjComponent < ActiveRecord::Base
  has_many :wj_component_pages, :dependent => :destroy, :order => "menu_order"
  has_many :wj_widgets,         :dependent => :destroy

  validates_length_of     :directory_name, :within => 1..64, :allow_nil => false
  validates_uniqueness_of :directory_name

  validates_length_of   :display_name, :within => 1..64, :allow_nil => false

  validates_length_of   :description, :within => 0..255, :allow_nil => false
  validates_length_of   :license,     :within => 1..8,   :allow_nil => true
  validates_length_of   :url,         :within => 1..255, :allow_nil => true
  validates_length_of   :author,      :within => 1..64,  :allow_nil => true

  # Returns the all components and its pages list if the component has one or more accessible pages.
  # The return object is a array list, each of which is [component, [page1, page2, ...]]
  def self.component_menu_list(user)
    self.find(:all, :include => :wj_component_pages).map { |component|
      [component, component.wj_component_pages.select{|page| page.accessible?(user)} ]
    }.select { |component, pages|
      pages.length != 0
    }
  end

  def self.widget_selection_list(user)
    self.find(:all, :include => :wj_widgets).map { |component|
      [component, component.wj_widgets.select{|widget| widget.available_for?(user)} ]
    }.select { |component, widgets|
      widgets.length != 0
    }
  end

end
