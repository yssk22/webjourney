class Blog::BlogSetting < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => "blog/blog")
  acts_as_relationship_permittable({
                                     :view    => {:all => true,  :tags => []},
                                     :manage  => {:all => false, :tags => []},
                                     :comment => {:all => true,  :tags => []}
                                   })

  string :title,       :validates => [[:length_of, {:in => 1..128, :allow_nil => false}]]
  string :description
  string :owner_login_name
  datetime :created_at
  datetime :updated_at

  array :recent_entries

  alias :owner_login_name :id
  view :public, :ids => {
    :map => <<-EOS
function(doc) {
  if(doc.class == "Blog::BlogSetting"){
    if( doc.relationship_keys &&
        doc.relationship_keys.view &&
        doc.relationship_keys.view.all ){
       emit(null, null);
    }
  }
}
EOS
  }, :recent_entry_ids => {
    :map => <<-EOS
function(doc) {
  if(doc.class == "Blog::BlogSetting"){
    if( doc.relationship_keys &&
        doc.relationship_keys.view &&
        doc.relationship_keys.view.all ){
      if( doc.recent_entries ){
        for(var i=0; i<doc.recent_entries.length; i++){
           emit(doc.recent_entries[i].updated_at, doc.recent_entries[i].blog_entry_id);
        }
      }
    }
  }
}
EOS
  }

  view :by_login_name, :all => {
    :map => <<-EOS
function(doc) {
  if(doc.class == "Blog::BlogSetting"){
    emit(doc._id, doc);
  }
}
EOS
  }, :entry_count => {
    :map => <<-EOS,
function(doc) {
  if(doc.class == "Blog::BlogSetting"){
    emit(doc._id, 0);
  }
  if(doc.class == "Blog::BlogEntry"){
    emit(doc.blog_setting_id, 1);
  }
}
EOS
    :reduce => <<-EOS
function(keys, values, rr){ return sum(values); }
EOS
  }

  view :all_tags, :count_by_id => {
    :map => <<-EOS,
function(doc){
  if(doc.class == "Blog::BlogEntry"){
    var tags = doc.tags;
    if( tags ){
       for(var i=0; i < tags.length; i++){
         emit([doc.blog_setting_id, tags[i]], 1);
       }
    }
  }
}
EOS
    :reduce => <<-EOS
function(keys, values, rr){ return sum(values); }
EOS
  }

  def self.get_public_recent_entries(limit=15)
    settings = {}
    result = Blog::BlogSetting.find_public_recent_entry_ids(:descending      => true,
                                                            :count           => limit,
                                                            :return_raw_hash => true,
                                                            :include_docs    => true)
    entry_ids = result[:rows].map { |hash|
      settings[hash["value"]] = Blog::BlogSetting.new(hash["doc"])
      hash["value"]
    }
    entries = Blog::BlogEntry.find(entry_ids).map do |entry|
      entry.setting = settings[entry.id]
      entry
    end
    result[:rows] = entries
    result
  end

  def find_entry(entry_id)
    Blog::BlogEntry.find_full_by_blog_setting_id_by_id(:first,
                                                       :key => [self._id, entry_id]);
  end

  def tags(start_with, case_sensitive = true)
    raise ArgumentError.new("start_with must be specified.") if start_with.nil?
    all_tags = self.class.find_all_tags_count_by_id(:startkey        => [self.id, start_with.to_s],
                                         :endkey          => [self.id, "#{start_with}\u0000"],
                                         :group           => true,
                                         :return_raw_hash => true)["rows"].map { |hash|
      [hash["key"].last, hash["value"]]
    }
    # sort by count
    all_tags.sort { |a, b|  (a.last <=> b.last) * -1}
  end


end
