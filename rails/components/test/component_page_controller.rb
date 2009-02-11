class Test::ComponentPageController < WebJourney::Component::PageController
  def index
    render :text => "OK", :status => 200
  end
end
