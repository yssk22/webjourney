class Sticky::TextController < WebJourney::WidgetController

  # GET /widgets/{:instance_id}/sticky/text/show/
  def show

  end

  # GET /widgets/{:instance_id}/sticky/text/edit/
  def edit

  end

  # POST /widgets/{:instance_id}/sticky/text/update/
  def update
    widget.parameters[:text] = params[:text]
    if widget.save
      render :action => "show"
    else
      render :action => "edit", :status => 400
    end
  end

end
