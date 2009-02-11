class Test::Widget3Controller < WebJourney::Component::WidgetController
  # GET /widgets/{:instance_id}/test/widget3/show/
  def show
  end

  # GET /widgets/{:instance_id}/test/widget3/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/test/widget3/update/
  def update
    render :action => "index"
  end

end
