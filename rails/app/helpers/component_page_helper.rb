module ComponentPageHelper
  def navigation_label(label)
    "<span class=\"label\">#{label}</li>"
  end

  def navigation_menu(label, options={}, html_options=nil)
    logger.wj_debug "highlight menu"
    html_options ||= {}
    if (options[:controller].nil? or options[:controller] == params[:controller]) &&
        (options[:action].nil? or options[:action] == params[:action])
      css_class = html_options[:class]
      html_options[:class] = "current #{css_class}"
    end
    link_to "<span>#{label}</span>", options, html_options
  end
end
