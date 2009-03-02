class Sticky::HtmlController < WebJourney::Component::WidgetController

  # GET /widgets/{:instance_id}/sticky/html/show/
  def show
  end

  # GET /widgets/{:instance_id}/sticky/html/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/sticky/html/update/
  def update
    widget.parameters[:html] = params[:html]
    if widget.save
      render :action => "show"
    else
      render :action => "edit", :status => 400
    end
  end

end
