class System::OpenIdController < WebJourney::Component::ComponentController
  def begin_authentication
    uri = params[:account][:open_id_uri]
    begin
      return redirect_to(consumer.begin(uri).redirect_url(open_id_realm,
                                                          open_id_return_to))
    rescue => e
      logger.wj_error "Failed to begin OpenID Authentication : #{uri}"
      logger.wj_error "(#{$!})"
      logger.wj_error e.backtrace.join("\n")
      set_flash(:error, "Failed to negotiate with your OpenID provider.")
      return redirect_to(:controller => "login_page",
                         :action => "login_with_open_id")
    end
  end

  def end_authentication
    res = consumer.complete(params.reject{|k,v|
                              request.path_parameters[k]
                            }, open_id_return_to)
    case res.status
    when OpenID::Consumer::SUCCESS
      user = WjUser.find_by_open_id_uri(params["openid.identity"])
      if user
        set_current_user(user)
        return redirect_to(my_page_system_account_path(user.login_name))
      else
        set_authenticated_open_id(params["openid.identity"])
        return redirect_to(:controller => "login_page",
                           :action     => :register_with_open_id)
      end
    when OpenID::Consumer::CANCEL
      set_flash(:error, "You must allow this site(#{open_id_realm}) on your OpenID provider.")
    when OpenID::Consumer::FAILURE
      set_flash(:error, "OpenID authentication failed. Please check your OpenID site..")
    else
      set_flash(:error, "OpenID confirmed with uknown status(#{res.status})")
    end
        return redirect_to(:controller => "login_page",
                           :action     => "login_with_open_id")
  end

  private
  def consumer
    unless @consumer
      dir = File.join(RAILS_ROOT, "tmp", "webjourney", "idstore")
      store = OpenID::Store::Filesystem.new(dir)
      @consumer = OpenID::Consumer.new(session, store)
    end
    @consumer
  end

  def open_id_realm
    # "components/system/open_id/{action}" is removed from the url.
    url_seguments = url_for(:only_path => false).split("/")
    url_seguments.pop
    url_seguments.pop
    url_seguments.pop
    url_seguments.pop
    url_seguments.join("/") + "/"
  end

  def open_id_return_to
    url_for({ :action     => "end_authentication" })
  end
end
