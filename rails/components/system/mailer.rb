class System::Mailer < WjMailer
  self.template_root = File.join(RAILS_ROOT, "components")
  include ActionController::UrlWriter
  def registration_confirmation(user, url)
    recipients user.email
    subject "Confirmation mail for account registration"
    body :user => user, :url => url
  end

  def reset_password_confirmation(user, url)
    recipients user.email
    subject "Confirmation mail for password reset"
    body :user => user, :url => url
  end

end
