class WjWidget < ActiveRecord::Base
  belongs_to :wj_component

  validates_presence_of :controller_name
  validates_uniqueness_of :controller_name, :scope => "wj_component_id"
  validates_presence_of :display_name

  yaml_attributes Hash, :parameters

  # Get the instance by <tt>{component}</tt>/<tt>{widget}</tt>
  def self.get(component, widget)
    self.find(:first, :conditions => ["wj_components.directory_name = ? AND wj_widgets.controller_name = ?", component, widget],
              :include => :wj_component)
  end

  # Returns widget controller fullname (including component name)
  def controller
    "#{self.wj_component.directory_name}/#{self.controller_name}"
  end

  # Returns widget controller class (not controller name string but controller Class object)
  def controller_class
    "#{controller}_controller".camelize.constantize
  end

  # Get whether the <tt>user</tt> can assess to use widget or not.
  def available_for?(user)
    true
    # [TODO] Widget ACL
    # required_roles = self.controller_class.read_inheritable_attribute(:require_roles_for_menu_item) || []
    # puts required_roles.inspect
    # required_roles.length > 0 ? user.has_roles?(*required_roles) : true
  end

  # Get the link path of this widget for <tt>filetype</tt>
  def link_path(filetype)
    base = "/components/#{self.wj_component.directory_name}"
    case filetype
    when :stylesheet ; then File.join(base, "stylesheets/#{self.controller_name}.css")
    when :image      ; then File.join(base, "images/#{self.controller_name}.png")
    when :javascript ; then File.join(base, "javascripts/#{self.controller_name}.js")
    else
      raise ArgumentError.new("filetype must be one of :stylesheet, :image, or javascript'")
    end
  end

  # Get the json for the javascript argument of EditPage#addWidget
  def json_for_new_widget
    {
      :component => self.wj_component.directory_name,
      :widget    => self.controller_name,
      :title => self.wj_component.display_name + "/" + self.display_name
    }.to_json
  end

  # Get the new instance of WjWidgetInstance
  def build_new_instance(page)
    raise ArgumentError.new("Cannot associate the new page with widgets.") unless page.id
    instance = WjWidgetInstance.new({ :wj_page_id  => page.id,
                                      :component   => self.wj_component.directory_name,
                                      :widget      => self.controller_name,
                                      :title       => self.wj_component.display_name + "/" + self.display_name,
                                      :parameters  => (self.parameters || {})})
  end

end
