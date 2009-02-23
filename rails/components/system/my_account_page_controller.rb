class System::MyAccountPageController < WebJourney::Component::PageController
  # see API details at http://www.webjourney.org/doc/classes/WebJourney/Component/PageController.html
  # require_roles :administrator, :only => :show
  # require_roles :user
  require_roles :user

  def index
    @account = current_user
    set_title "Account: #{@account.login_name}"
  end
end
