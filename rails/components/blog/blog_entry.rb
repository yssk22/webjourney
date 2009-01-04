class Blog::BlogEntry < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => "blog/blog")
  after_save :chain_update_setting

  string :blog_setting_id, :validates => [[:presense_of]]

  string :title, :validates => [[:length_of, {:in => 1..128, :allow_nil => false}]]
  string :link,  :allow_nil => true, :validates => [[:length_of, {:in => 1..512, :allow_nil => true}]]
  array :tags
  string :content
  datetime :post_date, :validates => [[:presense_of]]

  datetime :created_at
  datetime :updated_at

  string :created_by, :validates => [[:presense_of]]
  string :updated_by, :validates => [[:presense_of]]

  boolean :is_draft

  # nodoc
  SIMPLIFY_STATEMENTS = "doc.content = null;"
  # nodoc
  BY_BLOG_SETTING_ID_MAPS = {
    :by_post_date => <<-EOS,
function(doc) {
  if(doc.class == "Blog::BlogEntry"){
    $SIMPLIFY_OR_NOT;
    emit([doc.blog_setting_id, doc.post_date, doc.created_at], doc);
  }
}
EOS
    :by_id => <<-EOS
function(doc) {
  if(doc.class == "Blog::BlogEntry"){
    $SIMPLIFY_OR_NOT;
    emit([doc.blog_setting_id, doc._id], doc);
  }
}
EOS
  }

  view :simple_by_blog_setting_id, BY_BLOG_SETTING_ID_MAPS.map{|key, map| { key => {:map => map.gsub("$SIMPLIFY_OR_NOT", SIMPLIFY_STATEMENTS)} }}.inject{|r,i| r.merge(i)}
  view :full_by_blog_setting_id,   BY_BLOG_SETTING_ID_MAPS.map{|key, map| { key => {:map => map.gsub("$SIMPLIFY_OR_NOT", "")} }}.inject{|r,i| r.merge(i)}
  def self.build_refer_to(ref)
    @entry = self.default
    begin
      response = WebJourney::Util::Http.get_response(ref)
      if response.is_a?(Net::HTTPSuccess)
        @entry.link = ref
        if response.content_type =~ /^image\/.*/
          @entry.content = <<-EOS
<div class="ref">
<img src="#{ref}" width="100px"/>
</div>
<p> contents here ... </p>
EOS
        elsif response.content_type =~ /^text\/.*/
          # it can be analyzed if response is html
          result = WebJourney::Util::HtmlAnalyzer.analyze_from_html(response.body)
          @entry.title = result[:title] if result.has_key?(:title)
        else
          # binary or unknown type
          # nothing to do
        end
      else
        @entry.title = "Failed to fetch your reference link."
      end
    rescue Timeout::Error => e
      @entry.link = ref
      @entry.title = "Failed to fetch your reference(Timeout)."
    rescue => e
      logger.wj_debug e.message
      @entry.title = "Failed to fetch your reference(#{e.class})."
    end
    @entry
  end

  def tag_list
    if self.tags.blank?
      ""
    else
      self.tags.join(", ")
    end
  end

  def tag_list=(list)
    if list.blank?
      self.tags = nil
    else
      self.tags = list.to_s.split(",").map{|t| t.strip}.reject{|t| t.blank?}
    end
  end

  def setting
    @setting ||= Blog::BlogSetting.find(self.blog_setting_id)
  end

  def setting=(setting)
    @setting = setting
    self.blog_setting_id = setting.id
  end

  def get_comments(include_private = false)
    option = {
      :startkey     => [self.id, "\u0000"],
      :endkey       => [self.id],
      :descending   => true,
      :include_docs => true
    }
    if include_private
      Blog::BlogComment.find_by_blog_entry_id_include_private(option)
    else
      Blog::BlogComment.find_by_blog_entry_id_exclude_private(option)
    end
  end

  def to_hash
    hash = super()
    hash[:setting] = @setting.to_hash if @setting
    hash
  end

  # comment system


  private
  def chain_update_setting()
    h = { :blog_entry_id => self.id, :updated_at => self.updated_at }
    self.setting.recent_entries ||= []
    self.setting.recent_entries.reject! { |elm| elm[:blog_entry_id] == h[:blog_entry_id] }
    self.setting.recent_entries << { :blog_entry_id => self.id, :updated_at => self.updated_at }
    self.setting.recent_entries.shift    if self.setting.recent_entries.length > 5
    begin
      self.setting.save
      logger.wj_info "BlogEntry#chain_update_setting SUCCESS."
    rescue CouchResource::PreconditionFailed
      logger.wj_warn "BlogEntry#chain_update_setting FAILED."
    end
    # whether success or fail, this chain does not effect.
    true
  end

end
