class System::MyAccountPageController < WebJourney::Component::PageController
  # see API details at http://www.webjourney.org/doc/classes/WebJourney/Component/PageController.html
  # require_roles :administrators, :only => :show
  # require_roles :users
  require_roles :users

  def index
    @account = current_user
    set_title "Account: #{@account.login_name}"
  end
end
