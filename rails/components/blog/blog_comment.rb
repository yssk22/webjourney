class Blog::BlogComment < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => "blog/blog")
  string   :name,       :validates => [[:length_of, {:in => 1..64, :allow_nil => false}]]
  string   :login_name
  string   :url,        :validates => [[:length_of, {:in => 1..512, :allow_nil => true}]]
  string   :email,      :validates => [[:length_of, {:in => 1..512, :allow_nil => true}]]
  string   :blog_entry_id, :validates => [[:presense_of]]
  boolean  :is_private, :default => false
  string   :text,       :validates => [[:presense_of]]
  datetime :created_at

  view :by_blog_entry_id, :include_private => {
    :map => <<-EOS
function(doc){
  if(doc.class == "Blog::BlogComment"){
    emit([doc.blog_entry_id, doc.created_at], null);
  }
}
EOS
  }, :exclude_private => {
    :map => <<-EOS
function(doc){
  if(doc.class == "Blog::BlogComment"){
    if( !doc.is_private ){
       emit([doc.blog_entry_id, doc.created_at], null);
    }
  }
}
EOS
  }
end
