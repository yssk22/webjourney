class Blog::PublicController < WebJourney::ComponentController
  RECENT_ENTRIES_COUNT = 10
  def recent_entries
    @entries = Blog::BlogSetting.get_public_recent_entries(RECENT_ENTRIES_COUNT)
    respond_to do |format|
      format.xml  { render :text => @entries.to_xml,   :status => 200 }
      format.json { render :text => @entries.to_json , :status => 200 }
    end
  end
end
