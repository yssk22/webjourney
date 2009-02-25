# == Role Resource [components/system/roles]
class System::RolesController < WebJourney::ResourceController
  before_filter :load_role, :only => [:show, :update, :destroy]
  require_roles :administrator
  def index
    @roles = WjRole.order_by_name()
    respond_to_ok(@roles)
  end

  # == system/roles/defaults
  # === Get
  # Get default roles
  # === PUT or POST
  # Set default roles
  # ==== Request Parameter
  #
  # <tt>defaults</tt>:: a list of default role identifiers
  #
  def defaults
    case request.method
    when :get
      @roles = WjRole.defaults
      respond_to_ok(@roles)
    when :post, :put
      WjRole.update_default_roles(params[:defaults] || [])
      respond_to_nothing(200)
    else
      method_not_allowed!
    end
  end

end
