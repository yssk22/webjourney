class System::ConfigurationsController < WebJourney::ResourceController
  require_roles :administrator
  before_filter :load_config

  ATTRS_FOR_PAGE_DEFAULT =
    [
     :site_title,   :site_copyright, :site_keywords, :site_robots_index, :site_robots_follow,
     :design_width,  :design_width_unit,
     :design_lwidth, :design_lwidth_unit,
     :design_rwidth, :design_rwidth_unit,
    ]

  ATTRS_FOR_SMTP    = [:smtp_address, :smtp_port, :smtp_domain, :smtp_user_name, :smtp_password]
  ATTRS_FOR_ACCOUNT = [:account_allow_local_db_register, :account_allow_open_id_register]

  def page_default
    set_attrs(ATTRS_FOR_PAGE_DEFAULT, params[:config])
    save_and_response
  end

  def smtp
    set_attrs(ATTRS_FOR_SMTP, params[:config])
    save_and_response
  end

  def account
    set_attrs(ATTRS_FOR_ACCOUNT, params[:config])
    save_and_response
  end

  private
  def load_config
    @config = WjConfig.instance
  end

  def set_attrs(attrs, parameters)
    attrs.each do |attr|
      @config.send "#{attr}=", parameters[attr]
    end
  end

  def save_and_response
    if @config.save
      respond_to_ok(@config)
    else
      respond_to_error(error_resource_for(:config))
    end
  end
end
