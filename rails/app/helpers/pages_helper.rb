module PagesHelper
  def render_page_container_style(page)
    "width : #{WjConfig.container_width}"
  end

  def render_top_container_style(page)
    if page.widgets[:top].length > 0
      ""
    else
      "display : none;"
    end
  end

  def render_bottom_container_style(page)
    if page.widgets[:bottom].length > 0
      ""
    else
      "display : none;"
    end
  end

  def render_left_container_style(page)
    if page.widgets[:left].length > 0
      "width : #{page.left_container_width}"
    else
      "display : none;"
    end
  end

  def render_right_container_style(page)
    if page.widgets[:right].length > 0
      "width : #{page.right_container_width}"
    else
      "display : none;"
    end
  end

  def include_widget_javascripts()
    javascript_include_tag *(@widget_instances.map {  |widget|
      widget.javascript_path
    })
  end

  def mypage_link(user)
    return '&nbsp;' if user.anonymous?
    link_to "My Page", mypage_system_account_path(user.login_name), :class => "icon_mypage with_inline_icon"
  end

  def user_link(user)
    if user.anonymous?
      content_tag :span, h(user.display_name),
      :class => "icon_anonymous with_inline_icon"
    else
      link_to h(user.display_name), "#",
      :onclick => "$('#current_user').dialog({draggable: false, modal: true, resizable: false});",
      :class => "icon_user with_inline_icon"
    end
  end

  def login_link
    if current_user.anonymous?
      link_to "Login", {:controller => "system/login", :action => "index"}, :class => "icon_login with_inline_icon"
    else
      link_to "Logout", {:controller => "system/login", :action => "logout"}, :class => "icon_logout with_inline_icon"
    end
  end

  def create_link
    if WjPage.allow_to_create?(current_user)
      link_to "New", "javascript:void(0);",
      :class => "icon_page-create with_inline_icon",
      :onclick => "Page.createNew();"
    else
      nil
    end
  end

  def delete_link
    if @page.deleted_by?(current_user)
      link_to "Delete", "javascript:void(0);",
      :class => "icon_page-delete with_inline_icon",
      :onclick => "Page.destroy();"
    else
      nil
    end
  end

  def edit_link
    if @page.updated_by?(current_user)
      link_to "Edit", edit_page_url(@page.id), :class => "icon_page-edit with_inline_icon"
    else
      nil
    end
  end

  def page_settings_link
    link_to "Settings", "javascript:void(0);",
    :class => "icon_page-settings with_inline_icon",
    :onclick => "Page.showSettingsDialog();"
  end

  def page_permissions_link
    link_to "Share", "javascript:void(0);",
    :class => "icon_page-permissions with_inline_icon",
    :onclick => "Page.showPermissionsDialog();"
  end

  def save_link
    link_to "Save", "javascript:void(0);",
    :class => "icon_page-save with_inline_icon",
    :onclick => "Page.save();"
  end

  def back_link
    link_to "Back", "javascript:void(0);",
    :class => "icon_page-edit-back with_inline_icon",
    :onclick => "Page.back();"
  end

end
