class Blog::SettingsController < WebJourney::ComponentController
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TagHelper
  before_filter :load_setting, :only => [:show, :tags, :edit, :update, :destroy]
  before_filter :check_view,   :only => [:show, :tags]
  before_filter :check_owner,  :only => [:edit, :update, :destroy]


  def index
    # [TODO] pagination
    if params[:for]
      @settings = Blog::BlogSetting.find_by_login_name_all(:key => params[:for])
    else
      @settings = Blog::BlogSetting.find_by_login_name_all()
    end
    respond_to do |format|
      format.xml  { render :text => @settings.to_xml,   :status => 200 }
      format.json { render :text => @settings.to_json , :status => 200 }
    end
  end

  # GET /blog/settings/{id}/tags
  def tags
    @tags = @setting.tags(params[:q] || "")
    respond_to do |format|
      format.xml  { render :text => @tags.to_xml,   :status => 200 }
      format.json { render :text => @tags.to_json , :status => 200 }
      format.text { render :text => @tags.map { |a| a.join(",") }.join("\n") , :status => 200 }
    end
  end

  # GET /blog/settings/new
  def new
  end

  # GET /blog/settings/{id}/edit
  def edit
    @setting = Blog::BlogSetting.find(params[:id])
    not_found! unless @setting
  end


  # POST /blog/settings/
  def create
    @setting = Blog::BlogSetting.default
    @setting.id          = current_user.login_name
    @setting.title       = params[:setting][:title]
    @setting.description = params[:setting][:description]
    begin
      if @setting.save
        respond_to do |format|
          format.xml  { render :text => @setting.to_xml,   :status => 201 }
          format.json { render :text => @setting.to_json , :status => 201 }
        end
      else
        respond_to do |format|
          format.xml  { render :text => @setting.errors.to_xml,   :status => 400 }
          format.json { render :text => @setting.errors.to_json , :status => 400 }
        end
      end
    rescue CouchResource::PreconditionFailed
      # id conflicts
      respond_to do |format|
        format.xml  { render :text => { :error  => "Already exists."}.to_xml(:root => :errors),   :status => 409 }
        format.json { render :text => { :errors => "Already exists."}.to_json ,       :status => 409 }
      end
    end
  end

  # PUT /blog/settings/{id}
  def update
    @setting.title       = params[:setting][:title]
    @setting.description = params[:setting][:description]
    if @setting.save
      respond_to do |format|
        format.xml  { render :text => @setting.to_xml,   :status => 200 }
        format.json { render :text => @setting.to_json , :status => 200 }
      end
    else
      respond_to do |format|
        format.xml  { render :text => @setting.errors.to_xml,   :status => 400 }
        format.json { render :text => @setting.errors.to_json , :status => 400 }
      end
    end
  end

  # DELETE /blog/settings/{id}
  def destroy
    if @setting.destroy
      respond_to do |format|
        format.xml  { render :nothing => true,   :status => 200 }
        format.json { render :nothing => true,   :status => 200 }
      end
    else
      respond_to do |format|
        format.xml  { render :text => @setting.errors.to_xml,   :status => 400 }
        format.json { render :text => @setting.errors.to_json , :status => 400 }
      end
    end
  end

  private
  def load_setting
    @setting = Blog::BlogSetting.find(params[:id])
  end

  def check_owner
    forbidden! unless @setting.id == current_user.login_name
  end

  def check_view
    forbidden! unless @setting.allow_view?(current_user)
  end
end
