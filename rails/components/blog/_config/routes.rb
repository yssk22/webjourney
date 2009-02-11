WebJourney::Component::Routes.draw do |map|
  map.resources :settings, :member => {
    :tags => :get
  }, :collection => {
    :recent_entries => :get
  } do |setting|
    setting.resources :entries do |entry|
      entry.resources :comments
    end
  end
  # public blog entries resources
  map.connect "public/recent_entries.:format", :controller => "public", :action => "recent_entries"

  # blog page URIs
  # home/user/
  map.connect 'home/',                               :controller => "home", :action => "index"
  map.connect 'home/_all',                           :controller => "home", :action => "all_blogs"
  map.connect 'home/:id',                            :controller => "home", :action => "view_entries"
  map.connect 'home/:id/entries',                    :controller => "home", :action => "view_entries"
  map.connect 'home/:id/entries/:entry_id',          :controller => "home", :action => "view_entry"
  map.connect 'home/:id/by_month/:year/:month',      :controller => "home", :action => "view_by_month"
  map.connect 'home/:id/by_date/:year/:month/:day',  :controller => "home", :action => "view_by_date"
  map.connect 'home/:id/tagged_with/:tag',           :controller => "home", :action => "view_tagged_with"
end

