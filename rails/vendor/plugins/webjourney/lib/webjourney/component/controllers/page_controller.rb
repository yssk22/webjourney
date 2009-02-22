#
# A controller base class used in the component page.
#
# == Page Convention
#
# A component page is registered as WjCompontnPage model and the page is generally accessed via the site menu.
# The site menu has links to the index actions of component pages.
#
# === Role Based Access Control
#
# See dtails WebJourney::Component::Features::RoleBasedAccessControl and WebJourney::Features::RoleBasedAccessControl.
#
# === Layout
#
# A component page is applied to the default layout in RAILS_ROOT/components/layouts/component_page.html.erb and the page always returns HTML content.
# Your component page view file is rendered as a part of widget in the page, which is placed in the center container.
# A client can avoid applying layout with setting _layout=nil in the query string.
#
# when the default layout is applied, the html contents are as follows::
#
#   <div id="cpm" class="widget">
#     <div id="cpm_header" class="ui-dialog-titlebar header">
#        <span id="cpm_title" class="ui-dialog-title title">{title}</span>
#     </div>
#     <div id="cpm_body" class="body">
#
#     ... your component page view file is rendered here ...
#
#     </div>
#   </div>
#
# - "cpm" is an identifier prefix of the widget in the component page.
#
# The widget title is the same as the display name of WjComponentPage object, and it can be changed by the <tt>set_title</tt> method.
#
# === Navigation
#
# The layout detects the navigation file in <tt>RAILS_ROOT/components/{component}/{page}/_navigation.html</tt>,
# when the controller is located in <tt>RAILS_ROOT/components/{component}/{page}_controller.rb</tt>.
#
# If the navigation file exists, the layout always render the navigation file contents as a widget placed in the left container of the page.
# The navigation file example is as follows::
#
#   <% navigation do |n| -%>
#     <%= n.label "Password User" %>
#     <%= n.menu "Login",          {:action => "with_password"} %>
#     <%= n.menu "Register",       {:action => "register_with_password" } %>
#     <%= n.menu "Reset Password", {:action => "reset_password"} %>
#     <%= n.label "OpenID User" %>
#     <%= n.menu "Login",          {:action => "with_open_id" } %>
#     <%= n.menu "Register",       {:action => "register_with_open_id" } %>
#   <% end -%>
#
# Then the navigation widget is as follows::
#
#   <div id="cpn" class="widget">
#     <div id="cpn_header" class="ui-dialog-titlebar header">
#       <span id="cpn_title" class="ui-dialog-title title">Navigation</span>
#     </div>
#     <div id="cpn_body" class="body component_navigation">
#       <ul>
#         <li><span class="label">Password User</span></li>
#         <li><a href="/webjourney/components/system/login/with_password" class="current ">Login</a></li>
#         <li><a href="/webjourney/components/system/login/register_with_password">Register</a></li>
#         <li><a href="/webjourney/components/system/login/reset_password">Reset Password</a></li>
#         <li><span class="label">OpenID User</span></li>
#         <li><a href="/webjourney/components/system/login/with_open_id">Login</a></li>
#         <li><a href="/webjourney/components/system/login/register_with_open_id">Register</a></li>
#       </ul>
#     </div>
#   </div>
#
# - "cpn" is an identifier prefix of the widget in the component page.
#
# The applied navigation stylesheet is stored in <tt>RAILS_ROOT/public/stylesheets/webjourney/navigation.css</tt>.
#
class WebJourney::Component::PageController < WebJourney::Component::ComponentController
  include WebJourney::Component::Features::RoleBasedAccessControl
  layout :select_layout
  skip_filter   :load_component
  before_filter :load_component_page
  before_filter :set_has_navigation
  helper_method :page
  helper_method :has_navigation?
  helper_method :set_title

  # Returns a WjComponentPage object of the requested page.
  attr_reader :page

  # Set the page widget title in the page.
  def set_title(title)
    @_title = title
  end

  # Returns true when the comopnet page has _navigation file in it's view directory.
  def has_navigation?
    @has_navigation
  end

  private
  def select_layout
    layout = params[:_layout] || request.headers["X-WebJourney-Layout"] || "page"
    logger.wj_debug("Resolved layout: #{layout}")
    logger.wj_debug("View paths: #{view_paths.inspect}")
    case layout
    when "page"
      "webjourney/component_#{layout}"
    else
      nil
    end
  end

  def load_component_page
    c, p = self.controller_path.to_s.split("/")
    @page = WjComponentPage.get(c, p)
    not_found! unless @page

    @component = @page.wj_component
    true
  end

  def set_has_navigation
    path = File.join(RAILS_ROOT, "components", self.controller_path, "_navigation.html.erb")
    logger.wj_debug("nv_path :  #{path}")
    @has_navigation = File.exist?(path)
    true
  end
end

# WebJourney::ComponentPageController.send :include, WebJourney::Controllers::ComponentPage
