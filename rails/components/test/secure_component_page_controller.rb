class Test::SecureComponentPageController < WebJourney::Component::PageController
  require_roles :user, :committer
  def index
    render :text => "OK", :status => 200
  end
end
