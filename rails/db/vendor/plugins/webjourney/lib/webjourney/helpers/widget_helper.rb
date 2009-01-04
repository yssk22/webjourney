module WebJourney::WidgetHelper
  # Return a reference for javascript object of the widget.
  def js_object
    "Page.getWidgetInstance('#{widget._id}')"
  end

  # Returns a anchor link to invoke WidgetInstance#load method on the client javaScript.
  def link_to_load(name, url_options = {}, callbacks = {})
    link_to_function name, "#{js_object}.load(#{url_options.to_json}, #{callbacks.to_json})"
  end

  #
  # Returns a identifier of the widget.
  # If suffix is provided, the return value ("{identifier}_{suffix}") can be used for the dom identifier on your view template..
  #
  def dom_id(suffix)
    if suffix
      "#{widget._id}_#{suffix}"
    else
      widget._id
    end
  end

  #
  # Returns the id selector string for a jQuery argument
  #
  def dom_id_selector(suffix)
    "##{dom_id(suffix)}"
  end
end
