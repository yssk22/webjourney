class System::SiteConfigurationPagesController < WebJourney::ComponentPageController
  require_roles :administrator
  def index
    redirect_to :action => "page_header"
  end

  def page_header; end
  def page_design; end
  def smtp; end
  def account; end
end
