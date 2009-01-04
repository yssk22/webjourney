class WebJourney::ComponentController < ApplicationController
  layout :select_layout
  before_filter :load_component
  attr_reader   :component
  helper_method :component

  helper WebJourney::ComponentHelper

  before_filter do |controller|
    # set view_paths on RAILS_ROOT/components
    controller.view_paths=[File.join(RAILS_ROOT, "components")]
  end

  protected
  def load_component
    c, p = self.controller_path.to_s.split("/")
    @component = WjComponent.find_by_directory_name(c)
    unless @component
      logger.wj_debug("A controller within the component is requested but not found. Please check the component is registered.")
      logger.wj_debug("Component name: #{c}")
      raise WebJourney::NotFoundError.new
    end
    true
  end

  def select_layout
    layout = params[:_layout] || request.headers["X-WebJourney-Layout"]
    case layout
    when "page", "block"
      "webjourney/#{layout}"
    else
      layout
    end
  end
end
