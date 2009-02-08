#
# WjWidgetInstance is a CouchReosurce model that is used in the user developed widget controller.
# WjWidgetInstance objects are stored in wj_pages database specified in config/couchdb.yml
# WjWidgetInstance object can be referred in your original widget controller controller/view by <tt>instance</tt> method.
#
# It is described in WjPage API document how to add/update/delete widget instances in a page.
#
# WjWidgetInstance class does only handle updates of properties of title and parameters.
#
# === Properties
#
# <tt>title</tt>::      (rw)
# <tt>parameters</tt>:: (rw) a Hash datastore freely used by the widget controller implementation.
# <tt>wj_page_id</tt>:: (r)  used for the "join" key with the WjPage object.
# <tt>component</tt>::  (r)  component name
# <tt>widget</tt>::     (r)  widget name
#
class WjWidgetInstance < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => :wj_pages)

  string :wj_page_id
  string :component
  string :widget

  string :title,       :validates => [[:length_of, {:in => 0..128, :allow_nil => false}]]
  object :parameters

  # Returns WjPage object.
  # In your widget controller, you may get better peformance to use the page method instead of the instance.page method.
  def wj_page
    @wj_page ||= WjPage.find(self.wj_page_id)
  end

  # Returns WjWidget object.
  # In your widget controller, you may get better peformance to use the widget method instead of the instance.widget method.
  def wj_widget
    @wj_widget ||= WjWidget.get(self.component, self.widget)
  end

  # Returns the widget icon image path. This is the same as self.widget.image_path.
  def image_path
    "/components/#{component}/images/#{widget}.png"
  end

  # Returns the widget icon image path. This is the same as self.widget.javascript_path.
  def javascript_path
    "/components/#{component}/javascripts/#{widget}.js"
  end

  # Returns the widget icon image path. This is the same as self.widget.stylesheet_path.
  def stylesheet_path
    "/components/#{component}/stylesheets/#{widget}.css"
  end

  # Returns true if the javascript file exists
  def has_javascript?
    File.exist?(File.join(RAILS_ROOT, self.javascript_path))
  end

  # Returns true if the stylesheet file exists
  def has_stylesheet?
    File.exist?(File.join(RAILS_ROOT, self.javascript_path))
  end
end
