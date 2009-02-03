#
# WjComponent class is an ActiveRecord model for the component pages. It represents the page list included in the WjComponent.
# The data is stored or updated when a component installing/upgrading task is invoked.
# The original data is defined in each of components metadata yaml file located
# in <tt>RAILS_ROOT/components/{component_name}/_db/define/wj_component.yml</tt>.
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
# == Examples of shortcut methods
#
#   # <tt>login</tt> page defined in <tt>system</tt> component
#   page = WjComponentPage.get("system", "login")
#
#   page.controller           #=> "system/login"
#   page.controller_fullname  #=> "system/login_controller"
#   page.controller_class     #=> System::LoginController
#   page.image_path           #=> "/components/system/images/login.png"
#   page.javascript_path      #=> "/components/system/javascripts/login.js"
#   page.stylesheet_path      #=> "/components/system/stylesheets/login.css"
#
#
class WjComponentPage < ActiveRecord::Base
  belongs_to :wj_component

  validates_length_of :controller_name, :within => 1..64, :allow_nil => false
  validates_length_of :display_name, :within => 1..64,    :allow_nil => false

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

  # Returns true when the <tt>user</tt> has permission to access this page, otherwise returns false. assess to the page
  def accessible?(user)
    required_roles = self.controller_class.read_inheritable_attribute(:require_roles_for_menu_item) || []
    required_roles.length > 0 ? user.has_roles?(*required_roles) : true
  end
  alias :allow? :accessible?

  # --
  #
  # * The methods belows are shortcut methods
  #
  # ++

  # Returns the controller short name (<tt>'component/page'</tt> style) of the page.
  def controller
    "#{self.wj_component.directory_name}/#{self.controller_name}"
  end

  # Returns the controller long name (<tt>'component/page_controller'</tt> style) of the page,
  def controller_fullname
    "#{self.wj_component.directory_name}/#{self.controller_name}_controller"
  end

  # Returns the controller class object for the page
  def controller_class
    self.controller_fullname.camelize.constantize
  end

  # Returns the absolute image path of the page.
  # It should be <tt>/components/{component_name}/images/{controller_name}.png</tt>.
  def image_path
    "/components/#{self.wj_component.directory_name}/images/#{self.controller_name}.png"
  end

  # Returns the absolute javascript file path of the page.
  # It should be <tt>/components/{component_name}/images/{controller_name}.png</tt>.
  def javascript_path
    "/components/#{self.wj_component.directory_name}/javascripts/#{self.controller_name}.js"
  end

  # Returns the absolute stylesheet file path of the page.
  # It should be <tt>/components/{component_name}/images/{controller_name}.png</tt>.
  def stylesheet_path
    "/components/#{self.wj_component.directory_name}/stylesheets/#{self.controller_name}.css"
  end

end
