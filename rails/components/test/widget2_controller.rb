class Test::Widget2Controller < WebJourney::Component::WidgetController
  # GET /widgets/{:instance_id}/test/widget2/show/
  def show
  end

  # GET /widgets/{:instance_id}/test/widget2/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/test/widget2/update/
  def update
    render :action => "index"
  end

end
