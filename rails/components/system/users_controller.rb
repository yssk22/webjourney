# == Account Resource [components/system/users]
class System::UsersController < WebJourney::ResourceController
  before_filter :load_user, :only => [:show, :update, :destroy]
  require_roles :administrator
  def index
    filter_options = {}
    filter_options[:starts_with] = params[:starts_with] if params[:starts_with]
    filter_options[:status]      = params[:status]      if params[:status]
    filter_options[:class]       = case params[:type]
                                   when 'open_id'
                                     WjUser::OpenId
                                   when 'password'
                                     WjUser::LocalDB
                                   else
                                     WjUser
                                   end
    @users = WjUser.list(params)
    respond_to_ok(@users)
  end

  private
  def load_user
  end
end

