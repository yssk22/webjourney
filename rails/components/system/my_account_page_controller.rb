class System::MyAccountPageController < WebJourney::ComponentPageController
  require_roles :user
  def index
    @partial = case current_user
               when WjUser::OpenId
                 "open_id"
               when WjUser::BuiltIn::Administrator
                 "administrator"
               when WjUser::LocalDB
                 "local_db"
               end
  end
end
