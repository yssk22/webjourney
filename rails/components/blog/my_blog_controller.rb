class Blog::MyBlogController < WebJourney::ComponentPageController
  require_roles :user
  def index
  end

  def manage
    @setting = Blog::BlogSetting.find(params[:id])
    forbidden! unless @setting.allow_manage?(current_user)
    set_title(@setting.title)

    if params[:ref]
      @entry = Blog::BlogEntry.build_refer_to(params[:ref])
      @initial_container = "create_blog_entry_form_container"
      @init_script = <<-EOS
ManageEntry.switchContainer("create_blog_entry_form_container");
EOS
    end
    if params[:edit]
      entry = @setting.find_entry(params[:edit])
      not_found! unless entry
      @init_script = <<-EOS
ManageEntry.editBlogEntry("#{params[:edit]}");
EOS
    end

  end

end
