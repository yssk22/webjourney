#
# WjComponent class is an ActiveRecord model for the component pages. It represents the page list included in the WjComponent.
# The data is stored or updated when a component installing/upgrading task is invoked.
# The original data is defined in each of components metadata yaml file located
# in <tt>RAILS_ROOT/components/{component_name}/_db/define/wj_component_pages.yml</tt>.
#
# WjComponent object can be referred in your original component page controller/view by <tt>page</tt> method.
#
# == wj_component_pages.yml file specification
#
# The yaml file represents an array list, each element of which is a pair of the <tt>controller_name</tt> and the <tt>display_name</tt>.
# The order of the array is the same as the order of menu list on the site.
#
# To create a new component page and the definition yaml file of it, use <tt>wj_component_page</tt> generator.
#
# === Example of wj_component_pages.yml
#
#   - login:
#     display_name: Login
#   - my_account_page:
#     display_name: My Account Page
#   - users_and_roles_pages:
#     display_name: Users & Roles
#   - site_configuration_pages:
#     display_name: Site Configuration
#
# When the location of the above file is <tt>RAILS_ROOT/components/system/_db/define/wj_component_pages.yml</tt>,
# there should be four component page controller in the <tt>system</tt> component :
#
# - <tt>login_controller.rb</tt> : to define System::LoginController < ComponentPageController
# - <tt>my_account_page_controller.rb</tt> : to define System::MyAccountPageController < ComponentPageController
# - <tt>users_and_roles_pages_controller.rb</tt> : to define System::UsersAndRolesPagesController < ComponentPageController
# - <tt>site_configuration_pages_controller.rb</tt> : to define System::SiteConfigurationPagesController < ComponentPageController
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
#
class WjComponentPage < ActiveRecord::Base
  belongs_to :wj_component

  validates_length_of :controller_name, :within => 1..64, :allow_nil => false
  validates_length_of :display_name, :within => 1..64,    :allow_nil => false

  include WjComponentShortcuts


  # Returns the specified component page object
  def self.get(component_name, page_name)
    return WjComponentPage.find(:first,
                                :include => :wj_component,
                                :conditions => ["wj_components.directory_name = ? AND controller_name = ?", component_name, page_name])
  end

  # Returns DOM Element identifier that can be used in the component page view.
  # For example, the ERB code ::
  #
  #   <div id="<%= page.dom_id('a')%>">
  #   ...
  #   </div>
  #
  # will be
  #
  #   <div id="cpm_body_a">
  #   ...
  #   </div>
  #
  # <tt>"cpm_body_"</tt> is the prefix of DOM identifier. This assures the uniqueness of DOM identifier. In short,
  # The WebJourney framework does NOT use the DOM identifier which starts with <tt>'cpm_body_'</tt>.
  #
  # If the argument, <tt>suffix</tt>, is nil, this method returns <tt>'cpm_body'</tt>,
  # which is the DOM identifier of the <tt>div</tt> tag of the component main display block.
  #
  def dom_id(suffix = nil)
    if suffix
      "cpm_body_#{suffix}"
    else
      "cpm_body"
    end
  end

  # Returns true when the <tt>user</tt> has permission to access this page, otherwise returns false.
  def accessible?(user)
    required_roles = self.controller_class.read_inheritable_attribute(:require_roles_for_menu_item) || []
    required_roles.length > 0 ? user.has_roles?(*required_roles) : true
  end
  alias :allow? :accessible?


end
