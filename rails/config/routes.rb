ActionController::Routing::Routes.draw do |map|
  CONTROLLER_REGEX = /[a-z][a-z_0-9]*\/[a-z][a-z_0-9]*/i
  # Page Instance Routing
  map.resources :pages

  # Widget Instance Routing
  map.connect 'widgets/:instance_id/:controller/:action/:id', :requirements => {:controller => CONTROLLER_REGEX }

  # Routing defined in each component (in components/{component_name}/_config/routes.rb)
  Dir::entries(File.join(RAILS_ROOT, "components")).each do |dir|
    if dir != "." && dir != ".." &&
        File.exist?(File.join(RAILS_ROOT, "components", dir, "_config/routes.rb"))
      map.namespace(dir, :path_prefix =>"components/#{dir}") do |component_map|
        WebJourney::Routing::ComponentRoutes.mapper = component_map
        load File.join(RAILS_ROOT, "components", dir, "_config/routes.rb")
      end
    end
  end
  # Component Controller Routing (default)
  map.connect 'components/:controller/:action/:id', :requirements => {:controller => CONTROLLER_REGEX }

  # Root Path Routing
  map.root :controller => "top", :action => "index"
end
