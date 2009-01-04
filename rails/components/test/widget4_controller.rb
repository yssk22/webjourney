class Test::Widget4Controller < WebJourney::WidgetController

  # GET /widgets/{:instance_id}/test/widget4/show/
  def show
  end

  # GET /widgets/{:instance_id}/test/widget4/edit/
  def edit
  end

  # POST /widgets/{:instance_id}/test/widget4/update/
  def update
    render :action => "index"
  end

end
