class WebJourney::WidgetController < WebJourney::ComponentController
  helper WebJourney::WidgetHelper
  before_filter :load_widget
  before_filter :permission_check_general
  before_filter :permission_check_update, :only => [:update]
  before_filter :set_new_title, :only => [:update]
  helper_method :widget
  helper_method :page
  hide_action :widget
  hide_action :page

  def widget
    @widget
  end

  def page
    @widget.page
  end

  protected
  def load_widget
    @widget = WjWidgetInstance.find(params[:instance_id])
    raise WebJourney::NotFoundError.new unless @widget
    @page   = @widget.page
  end

  def permission_check_general
    reject_access! unless @page.shown_to?(current_user)
  end

  def permission_check_update
    reject_access! unless @page.updated_by?(current_user)
  end

  def set_new_title
    widget.title = params[:title]
  end
end
