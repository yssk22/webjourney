WebJourney::Component::Routes.draw do |map|
  # add Component original routing here
  #   map.resources :people
  #   # => /components/system/people get available
  #
  #   map.connect path/to/:controller/:action
  #   # => /components/system/path/to/:controller/:action get available

  map.resources :accounts,:member => {
    :my_page     => :get,
    :password    => :put,
    :activation  => :post,
  }, :collection => {
    :current        => :any,
    :password_reset => :post
  }
end
