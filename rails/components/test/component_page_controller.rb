class Test::ComponentPageController < WebJourney::ComponentPageController
  def index
    render :text => "OK", :status => 200
  end
end
