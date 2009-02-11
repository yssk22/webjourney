class System::ConfigurationsController < WebJourney::Component::ComponentController
  require_roles :administrator
  before_filter :load_config

  def page_header
    handle_request(:site_title, :site_description, :site_copyright, :site_keywords, :site_robots_index, :site_robots_follow)
  end

  def page_design
    handle_request(:design_width, :design_width_unit, :design_lwidth, :design_lwidth_unit, :design_rwidth, :design_rwidth_unit)
  end

  def smtp
    handle_request(:smtp_address, :smt_port,
                   :smtp_domain, :smtp_user_name, :smtp_password,
                   :smtp_authentication)
  end

  def account
    handle_request(:account_allow_local_db_register, :account_allow_open_id_register)
  end

  private
  def load_config
    @config = WjConfig.instance
  end

  def handle_request(*attrs)
    case request.method
    when :get
      # nothing to do
    when :post, :put
      attrs.each do |attr|
        @config[attr] = params[:config][attr]
      end
      logger.wj_debug("Save = #{@config.save!}")
      if @config.save
        flash.now[:info] = "Successfully updated."
      else
        flash.now[:error] = "Failed to update! Please check error messages."
      end
    when :delete
      raise WebJourney::Errors::MethodNotAllowedError
    end
  end
end
