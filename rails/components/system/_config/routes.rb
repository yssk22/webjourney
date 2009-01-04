# add Component original routing
WebJourney::Routing::ComponentRoutes.draw do |map|
  map.resources :accounts, :member => {
    :mypage => :get,
    :activation_form => :any,
    :reset_password_form => :any
  }, :collection => {
    :current => :any
  }

  map.resources :roles, :collection => {
    :defaults => :any
  }

  map.resource :configurations, :member => {
    :page_header => :any,
    :page_design => :any,
    :smtp        => :any,
    :account     => :any
  }

end
