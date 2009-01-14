# add Component original routing
WebJourney::Routing::ComponentRoutes.draw do |map|
  map.resources :accounts, :member => {
    :mypage     => :get,
    :password   => :post,
    :activation => :post
  }, :collection => {
    :reset_password => :post,
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
