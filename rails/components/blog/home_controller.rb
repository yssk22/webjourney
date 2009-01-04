class Blog::HomeController < WebJourney::ComponentPageController
  RECENT_COUNT = 10
  before_filter :load_setting, :except => [:index]

  # GET /components/blog/home
  def index
    set_title "New Entries from Public Blogs"
  end

  def view_entry
    @entry = @setting.find_entry(params[:entry_id])
    not_found! unless @entry
    if @setting.allow_comment?(current_user)
      @comment = BlogComment.new
      @comment.name = current_user.display_name
      @comments = @entry.get_comments(@setting.allow_manage?(current_user))
    end
  end

  # GET /components/blog/home/{login_name}
  def view_entries
  end

  # GET /components/blog/home/{login_name}/by_month/{year}/{month}
  def view_by_month
  end

  # GET /components/blog/home/{login_name}/by_month/{year}/{month}/{day}
  def view_by_date
  end

  def entry
  end

  protected
  def load_setting
    @setting = Blog::BlogSetting.find(params[:id])
    forbidden! unless @setting.allow_view?(current_user)
    set_title @setting.title
  end

end

