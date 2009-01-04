class TopController < ApplicationController
  def index
    redirect_to page_url(WjPage.top.id)
  end
end
