class System::PageListController < WebJourney::WidgetController

  # GET /widgets/{:instance_id}/system/pages/show/
  def show
    options = {}
    options[:count] = widget.parameters[:per_page] || 10

    [:startkey, :startkey_docid, :skip].each do |key|
      options[key] = params[key] if params.has_key?(key)
    end

    [:descending].each do |key|
      options[key] = (params[key] == "true") if params.has_key?(key)
    end
    [:previous].each do |key|
      options[key] = params[key] if params.has_key?(key)
    end

    @pages = case widget.parameters[:sort_by]
             when "updated_at"
               options[:descending] = true unless options.has_key?(:descending)
               WjPage.find_list_by_updated_at(options)
             when "title"
               WjPage.find_list_by_title(options)
             else
               options[:descending] = true unless options.has_key?(:descending)
               WjPage.find_list_by_updated_at(options)
             end
  end

  # GET /widgets/{:instance_id}/system/pages/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/system/pages/update/
  def update
    widget.parameters[:per_page] = params[:per_page].to_i
    if widget.save
      redirect_to :action => "show"
    else
      render :action => "edit", :status => 400
    end
  end

end
