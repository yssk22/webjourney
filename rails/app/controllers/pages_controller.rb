class PagesController < ApplicationController
  before_filter :load_page, :only => [:show, :edit, :update, :destroy]
  before_filter :load_widget_instances, :only => [:show, :edit]
  def index; end

  def show
    reject_access! unless @page.shown_to?(current_user)
  end

  def create
    reject_access! unless WjPage.allow_to_create?(current_user)
    page = WjPage.create_new(current_user)
    redirect_to page_url(page._id)
  end

  def edit
    reject_access! unless @page.updated_by?(current_user)
    @widget_selections = WjComponent.widget_selection_list(current_user)
  end

  def update
    reject_access! unless @page.updated_by?(current_user)
    %w(description copyright keywords robots_index robots_follow).each do |attr|
      @page[attr] = params[:page][attr]
    end
    @page.compose_widget_instance_layout(params[:page][:widgets])
    if @page.save
      render :text => @page.to_json, :status => 201
    else
      render :text => @page.errors.to_json, :status => 400
    end
  end

  def destroy
    reject_access! unless @page.deleted_by?(current_user)
    # [TODO] widget instances associated to the page have left as garbages.
    @page.destroy
    render :text => "OK",  :status => 200
  end

  private
  def load_page
    @page = WjPage.find(params[:id])
  end

  def load_widget_instances
    @widget_instances = @page.widget_instances
  end
end
