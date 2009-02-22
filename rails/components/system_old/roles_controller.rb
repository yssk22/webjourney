class System::RolesController < WebJourney::ComponentController
  require_roles :administrator

  def index
    # WjRole::BuiltIn.find(:all) does not work correctly (it depends on rails spec).
    @built_in_roles  = WjRole.find(:all,:conditions => ["wj_roles.type LIKE ?", "WjRole::BuiltIn::%"], :order => "name")
    @component_roles = WjRole::ComponentDefined.find(:all, :order => "name")
    @user_roles = WjRole::UserDefined.find(:all, :order => "name")
  end

  def defaults
    if request.method == :post || request.method == :put
      WjRole.update_default_roles(params[:defaults] || [])
    end
  end
end
