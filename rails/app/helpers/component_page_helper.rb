module ComponentPageHelper
  #
  # Component page navigation helper class
  #
  # == Stylesheets
  #
  # Located in /public/stylesheets/webjourney/navigation.css
  #
  # == Example
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
  class Navigation # :notnew:
    def initialize(view)
      @view = view
    end

    # Render non-linked menu label
    def label(label)
      str = content_tag :span, label, :class => "label"
      content_tag :li, str
    end

    # Render linked menu label. Arguments are the same as <tt>link_to</tt> method.
    def menu(label, options={}, html_options=nil)
      html_options ||= {}
      if (options[:controller].nil? or options[:controller] == params[:controller]) &&
          (options[:action].nil? or options[:action] == params[:action])
        css_class = html_options[:class]
        html_options[:class] = "current #{css_class}"
      end
      str = link_to(label, options, html_options)
      content_tag :li, str
    end

    private
    def method_missing(name, *args)
      @view.send name, *args
    end
  end

  #
  # Used in _navigation.html.erb to render the navigation menu.
  #
  def navigation(&proc)
    concat("<ul>", proc.binding)
    yield Navigation.new(self)
    concat("</ul>", proc.binding)
  end

end
