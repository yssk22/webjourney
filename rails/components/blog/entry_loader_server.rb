module Blog::EntryLoaderServer
  protected
  def load_by_id
    options = {
      :startkey         => ["\u0000"],
      :endkey           => [],
      :count            => 15,
      :descending       => true,
      :initial_startkey => [@setting.id, "\u0000"],
      :initial_endkey   => [@setting.id]
    }
    update_options_from_params(options)

    # insert settins_id filter into both startkey and endley
    options[:startkey].insert 0, @setting.id
    options[:endkey].insert 0, @setting.id

    if params[:include_content] == "true"
      @entries = Blog::BlogEntry.find_full_by_blog_setting_id_by_post_date(options)
    else
      @entries = Blog::BlogEntry.find_simple_by_blog_setting_id_by_post_date(options)
    end

    # remove filter not requred for the browser
    sanitize_paginate_options
  end

  private
  def update_options_from_params(options)
    [:startkey, :startkey_docid, :skip, :endkey].each do |key|
      options[key] = params[key] if params.has_key?(key)
    end

    [:descending].each do |key|
      options[key] = (params[key] == "true") if params.has_key?(key)
    end

    [:direction, :expected_offset].each do |key|
      options[key] = params[key] if params.has_key?(key)
    end
  end

  def sanitize_paginate_options
    [:next, :previous].each do |direction|
      if !@entries[direction].blank?
        # settings_id (which is included URI)
        [:startkey, :endkey].each do |key|
          @entries[direction][key].shift if @entries[direction].has_key?(key)

        end
        # initial_* (which should be hold on the REST server)
        @entries[direction].delete(:initial_startkey)
        @entries[direction].delete(:initial_endkey)
      end
    end
  end
end
