class WebJourney::Component::ComponentController < WebJourney::ApplicationController
  before_filter :load_component
  helper_method :component

  # Returns a WjComponent object of the requested controller.
  attr_reader   :component

  before_filter do |controller|
    # set view_paths on RAILS_ROOT/components
    controller.view_paths=[File.join(RAILS_ROOT, "components")]
  end

  private
  def load_component
    c, p = self.controller_path.to_s.split("/")
    @component = WjComponent.find_by_directory_name(c)
    not_found! unless @component
    true
  end
end
