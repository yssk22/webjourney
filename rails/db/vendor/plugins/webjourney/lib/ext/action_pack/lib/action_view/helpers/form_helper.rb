module ActionView::Helpers::FormHelper
  alias :text_field_original :text_field
  def text_field(object_name, method, options = {})
    override_default_keybehavior = options.delete(:override_default_keybehavior)
    unless override_default_keybehavior
      options[:onkeypress] = "#{options[:onkeypress]}; return event.keyCode != 13;"
    end
    text_field_original(object_name, method, options)
  end
end
