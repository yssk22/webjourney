class Test::SecureComponentPageController < WebJourney::ComponentPageController
  require_roles :user, :committer
  def index
    render :text => "OK", :status => 200
  end
end
