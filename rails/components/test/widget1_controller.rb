class Test::Widget1Controller < WebJourney::Component::WidgetController

  # GET /widgets/{:instance_id}/test/widget1/show/
  def show
  end

  # GET /widgets/{:instance_id}/test/widget1/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/test/widget1/update/
  def update
    render :action => "index"
  end

end
