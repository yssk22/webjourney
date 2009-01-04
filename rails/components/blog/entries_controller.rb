class Blog::EntriesController < WebJourney::ComponentController
  include Blog::EntryLoaderServer
  before_filter :load_setting
  before_filter :load_entry,         :only => [:show, :edit,  :update, :destroy]
  before_filter :check_allow_view,   :only => [:show, :index]
  before_filter :check_allow_manage, :only => [:new,  :edit,  :create, :update, :destroy]

  def index
    load_by_id
    # remove setting id from next, previous
    respond_to do |format|
      format.xml   { render :text => @entries.to_xml,   :status => 200 }
      format.json  { render :text => @entries.to_json , :status => 200 }
      format.atom  { render :status => 200 }
    end
  end

  def show
  end

  def new
    @entry = Blog::BlogEntry.default
  end

  def edit
  end

  def create
    @entry = Blog::BlogEntry.default
    @entry.blog_setting_id = @setting.id
    @entry.title      = params[:entry][:title]
    @entry.link       = params[:entry][:link]
    @entry.content    = params[:entry][:content]
    @entry.is_draft   = params[:entry][:draft]
    @entry.post_date  = params[:entry][:post_date] || "#{params[:entry]["post_date(1i)"]}/#{params[:entry]["post_date(2i)"]}/#{params[:entry]["post_date(3i)"]}"
    @entry.tag_list   = params[:entry][:tag_list]
    @entry.created_by = current_user.login_name
    @entry.updated_by = current_user.login_name

    if @entry.save
      respond_to do |format|
        format.xml  { render :text => @entry.to_xml,   :status => 201 }
        format.json { render :text => @entry.to_json,  :status => 201 }
      end
    else
      respond_to do |format|
        format.xml  { render :text => @entry.errors.to_xml,   :status => 400 }
        format.json { render :text => @entry.errors.to_json,  :status => 400 }
      end
    end
  end

  def update
    @entry.title      = params[:entry][:title]
    @entry.link       = params[:entry][:link]
    @entry.content    = params[:entry][:content]
    @entry.is_draft   = params[:entry][:draft]
    @entry.post_date  = params[:entry][:post_date] || "#{params[:entry]["post_date(1i)"]}/#{params[:entry]["post_date(2i)"]}/#{params[:entry]["post_date(3i)"]}"
    @entry.tag_list   = params[:entry][:tag_list]
    @entry.updated_by = current_user.login_name

    if @entry.save
      respond_to do |format|
        format.xml  { render :text => @entry.to_xml,   :status => 200 }
        format.json { render :text => @entry.to_json,  :status => 200 }
      end
    else
      respond_to do |format|
        format.xml  { render :text => @entry.errors.to_xml,   :status => 400 }
        format.json { render :text => @entry.errors.to_json,  :status => 400 }
      end
    end
  end

  def destroy
    if @entry.destroy
      respond_to do |format|
        format.xml  { render :nothing => true, :status => 200 }
        format.json { render :nothing => true, :status => 200 }
      end
    else
      respond_to do |format|
        format.xml  { render :text => @entry.errors.to_xml,   :status => 400 }
        format.json { render :text => @entry.errors.to_json,  :status => 400 }
      end
    end
  end

  private
  def load_setting
    @setting = Blog::BlogSetting.find(params[:setting_id])
  end

  def load_entry
    @entry = @setting.find_entry(params[:id])
    not_found! unless @entry
  end

  def check_allow_manage
    forbidden! unless @setting.allow_manage?(current_user)
  end

  def check_allow_view
    forbidden! unless @setting.allow_view?(current_user)
  end
end
