#
# WjWidget class is an ActiveRecord model for the widget master data.
# It represents the widget list included in the WjComponent.
# The data is stored or updated when a component installing/upgrading task is invoked.
# The original data is defined in each of components metadata yaml file located
# in <tt>RAILS_ROOT/components/{component_name}/_db/define/wj_widgets.yml</tt>.
#
# WjWidget object can be referred in your original widget controller/view implementation
# by <tt>widget</tt> method.
#
# == wj_widgets.yml file specification
#
# The yaml file represents an array list, each element of which is a pair of the <tt>controller_name</tt> and the <tt>display_name</tt>.
# The order of the array is the same as the order of menu list on the site.
#
# To create a new widget and the definition yaml file of it, use <tt>wj_widget</tt> generator.
#
# === Example of wj_widgets.yml
#
#   - text:
#       display_name: Text
#   - html:
#       display_name: Html
#   - feed:
#       display_name: Feed
#
# When the location of the above file is <tt>RAILS_ROOT/components/sticky/_db/define/wj_widgets.yml</tt>,
# there should be trhee widget controller in the <tt>widget</tt> component :
#
# - <tt>test_controller.rb</tt> : to define Sticky::TextController < WidgetController
# - <tt>html_controller.rb</tt> : to define System::HtmlController < WidgetController
# - <tt>feed_controller.rb</tt> : to define System::FeedController < WidgetController
#
# == Relationships and Properties
# === Relationships
#
# <tt>wj_component</tt>:: belongs_to for WjComponent
#
# === Properties
#
# <tt>controller_name</tt>::    (rw) should be matched with the controller name (without the '_controller' suffix).
# <tt>display_name</tt>::       (rw)
# <tt>parameters</tt>::         (rw) Key-Value pairs for the default value of the widget instance parameters.
#
class WjWidget < ActiveRecord::Base
  belongs_to :wj_component

  validates_presence_of   :controller_name
  validates_uniqueness_of :controller_name, :scope => "wj_component_id"
  validates_presence_of   :display_name

  include WjComponentShortcuts

  yaml_attributes Hash, :parameters

  # Returns the specified widget object.
  def self.get(component, widget)
    self.find(:first,
              :include => :wj_component,
              :conditions => ["wj_components.directory_name = ? AND wj_widgets.controller_name = ?", component, widget])
  end

  # Returns true when the <tt>user</tt> has permission to use this widget, otherwise returns false.
  def available_for?(user)
    # [TODO] Widget ACL
    # required_roles = self.controller_class.read_inheritable_attribute(:require_roles_for_menu_item) || []
    # puts required_roles.inspect
    # required_roles.length > 0 ? user.has_roles?(*required_roles) : true
    true
  end
  alias :allow? :available_for?

  # Returns the json string for the argument in javascript front-end.
  def json_for_new_widget
    {
      :component => self.wj_component.directory_name,
      :widget    => self.controller_name,
      :title     => self.wj_component.display_name + "/" + self.display_name
    }.to_json
  end

  # Returns the new widget instance associated with the <tt>page</tt>, which is not saved.
  def build_new_instance(page)
    raise ArgumentError.new("Cannot associate the new page with widgets.") unless page.id
    WjWidgetInstance.new({ :wj_page_id  => page.id,
                           :component   => self.wj_component.directory_name,
                           :widget      => self.controller_name,
                           :title       => self.wj_component.display_name + "/" + self.display_name,
                           :parameters  => (self.parameters || {})})
  end

end
