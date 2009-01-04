class System::UsersAndRolesPagesController < WebJourney::ComponentPageController
  require_roles :administrator
  def index
  end
end
