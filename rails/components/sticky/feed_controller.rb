class Sticky::FeedController < WebJourney::WidgetController

  # GET /widgets/{:instance_id}/sticky/feed/show/
  def show
    if widget.parameters[:url].blank?
      return render(:action => "no_feed_specified")
    else
      begin
        load_feed
      rescue WebJourney::FeedReader::FeedFetchError => e
        @error = e
        return render(:action => "feed_fetch_error")
      end
    end
  end

  # GET /widgets/{:instance_id}/sticky/feed/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/sticky/feed/update/
  def update
    widget.parameters[:url]        = params[:url]
    widget.parameters[:list_items] = params[:list_items].to_i
    if widget.save
      redirect_to :action => "show"
    else
      render :action => "edit", :status => 400
    end
  end

  private
  def load_feed
    response, @feed = WebJourney::FeedReader.fetch(widget.parameters[:url])
    @items = @feed.items[0..(widget.parameters[:list_items] - 1)]
  end
end
