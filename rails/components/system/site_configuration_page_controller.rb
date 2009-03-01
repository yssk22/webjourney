class System::SiteConfigurationPageController < WebJourney::Component::PageController
  require_roles :administrator
  def index
    redirect_to :action => "page_default"
  end

  def page_default
    set_title "Page Settings"
    @config = WjConfig.instance
  end

  def smtp
    set_title "SMTP Settings"
    @config = WjConfig.instance
  end

  def account
    set_title "Account Settings"
    @config = WjConfig.instance
  end

end
