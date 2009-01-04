module FlashHelper
  # Returns flash messages if exists.
  # defaul style is the same as 'key' parameter and the string is formated by simple_format method.
  #
  #   message_from_flash(:error)
  #   => <div style="error"><%=simple_format flash[:error] %></div>
  #
  #   message_from_flash(:error, 'warn')
  #   => <div style="warn"><%=simple_format flash[:error] %></div>
  #
  #   message_from_flash(:error, 'warn', false)
  #   => <div style="warn"><%= flash[:error] %></div>
  #
  def message_from_flash(key, style=nil, format=true)
    dom_id_str = "flash"
    style = key.to_s unless style
    id = "#{dom_id_str}_#{key}_#{dom_id_str.object_id}"
    return flash_effect(id) + content_tag(:div, simple_format(flash[key]),
                                          :id    => id,
                                          :class => style) if flash[key]
    nil
  end

  # Return flash.now messages if exits. This is the similar to #message_from_flash(key, style, format)
  def message_from_flash_now(key, style=nil, format=true)
    dom_id_str = "flash"
    style = key.to_s unless style
    id = "#{dom_id_str}_#{key}_#{dom_id_str.object_id}"
    return flash_effect(id) + content_tag(:div, simple_format(flash.now[key]),
                                          :id => id,
                                          :class => style) if flash.now[key]
    nil
  end

  private
  def flash_effect(id)
    <<-EOS
<script type="text/javascript">
$(document).ready(function(){$("##{id}").effect("bounce", { times : 3}, 300);});
</script>
EOS
  end

end
