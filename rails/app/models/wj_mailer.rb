# Automatically Mailer Formatting Class
# If your components mail to some users, define mail class by extending this class.
class WjMailer < ActionMailer::Base
  def create!(*)
    super
    # fetch mail settings from siteconfig objects
    WjConfig.instance.update_action_mailer
    @mail.subject = "[#{WjConfig[:site_title]}] #{@mail.subject}"
    @mail.from    = "noreplay <noreplay@#{WjConfig[:smtp_address]}>"
    @mail.body    =<<-EOS
** ------------------------------------ **
** THIS MAIL IS DELIVERED AUTOMATICALLY **
**      DO NOT REPLY TO THIS MAIL       **
** ------------------------------------ **

#{@mail.body}

--
If you have any questions about this mail,
please contact the site administrator (#{WjUser::BuiltIn::Administrator.me.email})

EOS
  end

  # Testing mail to an address
  def test_mail(address)
    recipients address
    subject "test mail"
    body
  end
end
