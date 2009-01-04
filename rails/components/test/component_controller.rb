class Test::ComponentController < WebJourney::ComponentController
  require_roles :administrator, :only => :administrator_action
  require_roles :user, :committer, :only => :committer_action, :all => true

  def index
    render :text => "OK", :status => 200
  end

  def administrator_action
    render :text => "OK", :status => 200
  end

  def committer_action
    render :text => "OK", :status => 200
  end

end
