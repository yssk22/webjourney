#
# WjComponent class is an ActiveRecord model for the component meta data.
# The data is stored or updated when a component installing/upgrading task is invoked.
# The original data is defined in each of components metadata yaml file located
# in RAILS_ROOT/components/{component_name}/_db/define/wj_component.yml.
#
# == wj_component.yml file specification
#
# The yaml file is a flat property list, all of which are :
#
# - <tt>display_name</tt> : the name displayed on the site.
# - <tt>license</tt> : the license name such as MIT, GPL, LGPL, BSD, ... .
# - <tt>url</tt> : the publisher url of the component.
# - <tt>author</tt> : the author of the component.
# - <tt>description</tt> : the short description(within 255 chars) of the component.
#
# Properties except display_name are not used in the current framework. They are reserved properties in the future use.
# The <tt>display_name</tt> is used for the label to be displayed on the site.
#
# To create a new component and the definition yaml file of it, use <tt>wj_component</tt> generator.
#
# === Example of wj_component_pages.yml
#
#    display_name: "Sticky"
#    license     : "MIT"
#    url         : "http://www.webjourney.org/wiki/components/sticky"
#    author      : "yssk22"
#    description : "Sticky is a built-in component for adding various simple widgets"
#
# == Relationships and Properties
# === Relationships
#
# <tt>wj_component_pages</tt>:: has_many for WjComponentPage
# <tt>wj_widgets</tt>::         has_many for WjWidget
#
# === Properties
#
# <tt>directory_name</tt>::     (rw) should be matched with the directory name of the component.
# <tt>display_name</tt>::       (rw)
# <tt>license</tt>::            (rw)
# <tt>url</tt>::                (rw)
# <tt>author</tt>::             (rw)
#
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

  # Returns the all components and its pages list, which can be accessible
  # for the <tt>user</tt>(see WjComponentPage#accessible?).
  # Comopnents which have no accessible pages are not included in the return value.
  #
  # The return value is a array list, each of which is <tt>[component, [page1, page2, ...]]</tt>.
  #
  def self.component_menu_list(user)
    self.find(:all, :include => :wj_component_pages).map { |component|
      [component, component.get_accessible_pages_for(user)]
    }.select { |component, pages|
      pages.length != 0
    }
  end

  # Returns the all components and its widgets list, which can be available
  # for the <tt>user</tt>(see WjWidget#available_for?).
  # Comopnents which have no available widgets are not included in the return value.
  #
  # The return value is a array list, each of which is <tt>[component, [widget1, widget2, ...]]</tt>.
  #
  def self.widget_selection_list(user)
    self.find(:all, :include => :wj_widgets).map { |component|
      [component, component.get_available_widgets_for(user)]
    }.select { |component, widgets|
      widgets.length != 0
    }
  end


  # Returns the related WjComponentPage objects each of which is accessible.
  #
  def get_accessible_pages_for(user)
    self.wj_component_pages.select{|page| page.accessible?(user)}
  end

  # Returns the related WjWidget objects each of which is available.
  def get_available_widgets_for(user)
    self.wj_widgets.select{|widget| widget.available_for?(user)}
  end
end
