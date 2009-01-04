atom_feed do |feed|
  feed.title(@setting.title)
  feed.updated((@entries[:rows].first.created_at))

  for post in @entries[:rows]
    feed.entry(post, :url => {:controller => "home", :action => "entry", :id => post.id}) do |entry|
      entry.title(post.title)
      entry.content(post.content, :type => 'html')
    end
  end
end
