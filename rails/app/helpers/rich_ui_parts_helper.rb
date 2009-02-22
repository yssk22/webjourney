module RichUiPartsHelper

  #
  # Returns a javascript to align a certain width styled form.
  #
  def align_form(dom_id, option={})
    label_width = option[:label_width]
    javascript_tag <<-EOS
jQuery(document).ready(function(){
    jQuery('##{dom_id} fieldset').css("padding-left", "#{label_width}px");
    jQuery('##{dom_id} fieldset legend').css("margin-left", "-#{(label_width - 10)}px");
    jQuery('##{dom_id} fieldset div.error').css("margin-left", "-#{(label_width - 10)}px");
    jQuery('##{dom_id} fieldset div.field label.name').css("width", "#{label_width}px");
    jQuery('##{dom_id} fieldset div.field label.name').css("margin-left", "-#{label_width}px");
});
EOS
  end

  #
  # Reurns a div block with a javascript sentence that loads the contents of the specified <tt>url</tt>.
  # The contents loader script is triggered on the ready event of the document.
  #
  def lazy_load_block(url, html_options)
    dom_id = "lazy_load_block"
    dom_id = "#{dom_id}_#{dom_id.object_id}"
    html_options[:id] ||= dom_id
    css_class = html_options[:class]
    html_options[:class] = "lazy_load #{css_class}"
    lazy_load_block_script(html_options[:id], url) +
      content_tag(:div,
                  content_tag(:p,
                              content_tag(:span,
                                          "Now loading ... ",
                                          :class => "with_inline_icon icon-now_loading")),
                  html_options)
  end

  def toggle_button(dom_id, label = "")
    onclick = <<-EOS
if( $(this).hasClass('icon_toggle_expand') ){
  $(this).removeClass('icon_toggle_expand');
  $(this).addClass('icon_toggle_fold');
  $('##{dom_id}').css('display', 'block');
}else{
  $(this).removeClass('icon_toggle_fold');
  $(this).addClass('icon_toggle_expand');
  $('##{dom_id}').css('display', 'none');
}
EOS
    link_to_function(label, onclick,
        :class => "with_inline_icon icon_toggle_expand")
  end

  private
  def lazy_load_block_script(id, url)
    javascript_tag "$(document).ready(function(){$('##{id}').load(#{url.to_json});});"
  end
end
