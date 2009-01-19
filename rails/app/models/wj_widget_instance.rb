class WjWidgetInstance < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => :wj_pages)

  string :wj_page_id
  string :component
  string :widget

  string :title,       :validates => [[:length_of, {:in => 0..128, :allow_nil => false}]]
  object :parameters

  def page
    @page ||= WjPage.find(self.wj_page_id)
  end

  def image_path
    "/components/#{component}/images/#{widget}.png"
  end

  def javascript_path
    "/components/#{component}/javascripts/#{widget}.js"
  end

  def has_javascript?
    File.exist?(File.join(RAILS_ROOT, self.javascript_path))
  end

  def stylesheet_path
    "/components/#{component}/stylesheets/#{widget}.css"
  end

  def has_stylesheet?
    File.exist?(File.join(RAILS_ROOT, self.javascript_path))
  end


end
