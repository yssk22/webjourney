class System::ComponentsPageController < WebJourney::Component::PageController
  # see API details at http://www.webjourney.org/doc/classes/WebJourney/Component/PageController.html
  # require_roles :administrator, :only => :show
  # require_roles :users
  require_roles :administrator

  def index
  end
end
