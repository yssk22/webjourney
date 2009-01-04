class WjUser::Profile < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => :wj_user_profiles)
  object :relationships

  # add relationship with the other user.
  def update_relationship(other, tags)
    self.relationships ||= {}
    self.relationships[other.login_name] = tags.is_a?(Array) ? tags : [tags]
  end

  # remove relationship with the other user.
  def remove_relationship(other)
    self.relationships ||= {}
    self.relationships.delete(other.login_name)
  end

  
  # Get whether the user is related to <tt>other</tt>:
  # - <tt>tag</tt> : filter tag
  #
  def related_to?(other, tag = nil)
    tags = (self.relationships || {})[other.login_name]
    if tags
      if tag
        tags.include?(tag)
      else
        true
      end
    else
      false
    end
  end
end
