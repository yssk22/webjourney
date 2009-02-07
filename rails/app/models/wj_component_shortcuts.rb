#
# This module defines common shortcut methods for WjComponentPage and WjWidget
#
# == Examples of shortcut methods
#
# === shortcuts in WjComponentPage
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
# === shortcuts in WjWidget object
#
#   # <tt>text</tt> widget defined in <tt>sticky</tt> component
#   widget = WjWidget.get("system", "login")
#   widget.controller           #=> "stikey/text"
#   widget.controller_fullname  #=> "stikey/text_controller"
#   widget.controller_class     #=> Sticky::TextController
#   widget.image_path           #=> "/components/sticky/images/text.png"
#   widget.javascript_path      #=> "/components/sticky/javascripts/text.js"
#   widget.stylesheet_path      #=> "/components/sticky/stylesheets/text.css"
#
module WjComponentShortcuts
  # --
  #
  # * The methods belows are shortcut methods
  #
  # ++

  # Returns the controller short name (<tt>'component/page'</tt> style) of the page or widget.
  def controller
    "#{self.wj_component.directory_name}/#{self.controller_name}"
  end

  # Returns the controller long name (<tt>'component/page_controller'</tt> style) of the page or widget,
  def controller_fullname
    "#{self.wj_component.directory_name}/#{self.controller_name}_controller"
  end

  # Returns the controller class object for the page
  def controller_class
    self.controller_fullname.camelize.constantize
  end

  # Returns the absolute image path of the page or widget.
  def image_path
    "/components/#{self.wj_component.directory_name}/images/#{self.controller_name}.png"
  end

  # Returns the absolute javascript file path of the page or widget.
  def javascript_path
    "/components/#{self.wj_component.directory_name}/javascripts/#{self.controller_name}.js"
  end

  # Returns the absolute stylesheet file path of the page or widget.
  def stylesheet_path
    "/components/#{self.wj_component.directory_name}/stylesheets/#{self.controller_name}.css"
  end
end
