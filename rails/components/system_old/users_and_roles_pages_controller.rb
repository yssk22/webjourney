class System::UsersAndRolesPagesController < WebJourney::Component::PageController
  require_roles :administrators
  def index
  end
end
