module RichUiActionHelper
  #
  # Returns a javascript which disable submit and change styles to "now loading".
  #
  def disable_submit_button(dom_id)
    disable(dom_id) +
      change_css_class(dom_id, :submitting)
  end

  #
  # Returns a javascript which enable submit button and change styles to the normal.
  #
  def enable_submit_button(dom_id)
    enable(dom_id) +
      change_css_class(dom_id, :submit)
  end

  private
  def disable(dom_id)
    "$('##{dom_id}').attr('disabled', 'disabled');"
  end

  def enable(dom_id)
    "$('##{dom_id}').attr('disabled', '');"
  end

  def change_css_class(dom_id, *styles)
    "$('##{dom_id}').attr('class', '#{styles.join(' ')}');"
  end
end
