class WjComponentPage < ActiveRecord::Base
  belongs_to :wj_component

  validates_length_of :controller_name, :within => 1..64, :allow_nil => false
  validates_length_of :display_name, :within => 1..64,    :allow_nil => false

  # Get the specified component page object
  def self.get(component_name, page_name)
    return WjComponentPage.find(:first,
                                :include => :wj_component,
                                :conditions => ["wj_components.directory_name = ? AND controller_name = ?", component_name, page_name])
  end

  # Returns DOM Element id for Component Main block
  def dom_id(suffix = nil)
    if suffix
      "cpm_body_#{suffix}"
    else
      "cpm_body"
    end
  end

  # Get the controller shortname of the page (including component directory name)
  def controller
    "#{self.wj_component.directory_name}/#{self.controller_name}"
  end

  # Get the controller fullname (with the suffix, '_controller') for the page
  def controller_fullname
    "#{self.wj_component.directory_name}/#{self.controller_name}_controller"
  end

  # Get the controller class object for the page
  def controller_class
    self.controller_fullname.camelize.constantize
  end

  # Get whether the <tt>user</tt> can assess to the page or not.
  def accessible?(user)
    required_roles = self.controller_class.read_inheritable_attribute(:require_roles_for_menu_item) || []
    required_roles.length > 0 ? user.has_roles?(*required_roles) : true
  end

    def image_path
    "/components/#{self.wj_component.directory_name}/images/#{self.controller_name}.png"
  end

  def javascript_path
    "/components/#{self.wj_component.directory_name}/javascripts/#{self.controller_name}.js"
  end

  def stylesheet_path
    "/components/#{self.wj_component.directory_name}/stylesheets/#{self.controller_name}.css"
  end


end
