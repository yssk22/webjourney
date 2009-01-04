class Blog::CommentsController < WebJourney::ComponentController
  before_filter :load_setting_and_entry

  def index
  end

  def create
    @comment = Blog::BlogComment.new
    @comment.name  = params[:comment][:name]
    @comment.login_name = current_user.login_name
    @comment.blog_entry_id = @entry.id
    @comment.text  = params[:comment][:text]
    @comment.email = params[:comment][:email] unless params[:comment][:email].blank?
    @comment.url   = params[:comment][:url]   unless params[:comment][:url].blank?

    if @comment.save
      respond_to do |format|
        format.xml   { render :text => @comment.to_xml,   :status => 200 }
        format.json  { render :text => @comment.to_json, :status => 200 }
      end
    else
      respond_to do |format|
        format.xml   { render :text => @comment.errors.to_xml,   :status => 400 }
        format.json  { render :text => @comment.errors.to_json , :status => 400 }
      end
    end
  end

  def destroy
  end

  private
  def load_setting_and_entry
    @setting = Blog::BlogSetting.find(params[:setting_id])
    forbidden! unless @setting.allow_comment?(current_user)
    @entry = @setting.find_entry(params[:entry_id])
    not_found! unless @entry
  end
end
