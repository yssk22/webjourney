#
# WjConfig class is an ActiveRecord model for the site level configuation stored in the database.
#
# == Relationships and Properties
# === Relationships#
# === Properties
# ==== Default page design
#
# <tt>design_theme</tt>::       (rw)
# <tt>design_width</tt>::       (rw)
# <tt>design_width_unit</tt>::  (rw)
# <tt>design_lwidth</tt>::      (rw)
# <tt>design_lwidth_unit</tt>:: (rw)
# <tt>design_rwidth</tt>::      (rw)
# <tt>design_rwidth_unit</tt>:: (rw)
#
# ==== Default page head tag
#
# <tt>site_title</tt>:: (rw)
# <tt>site_robots_index</tt>:: (rw)
# <tt>site_robots_follow</tt>:: (rw)
# <tt>site_keywords</tt>:: (rw)
# <tt>site_description</tt>:: (rw)
# <tt>site_copyright</tt>:: (rw)
#
# ==== SMTP settings
#
# <tt>smtp_address</tt>:: (rw)
# <tt>smtp_domain</tt>:: (rw)
# <tt>smtp_port</tt>:: (rw)
# <tt>smtp_user_name</tt>:: (rw)
# <tt>smtp_password</tt>:: (rw)
# <tt>smtp_authentication</tt>:: (rw)
#
# ==== account control
#
# <tt>account_allow_local_db_register</tt>:: (rw)
# <tt>account_allow_open_id_db_register</tt>:: (rw)
#

class WjConfig < ActiveRecord::Base
  DesignWidthUnits = %w(mm cm in pt pc em ex px %)
  Id = 1

  validates_length_of :design_theme, :in => 1..64
  validates_format_of :design_theme, :with => /[a-zA-Z0-9_]+/


  [:width, :lwidth, :rwidth].each do |attr|
    validates_inclusion_of    "design_#{attr}",      :in => 1..1024
    validates_numericality_of "design_#{attr}",      :only_integer => true, :allow_nil => false
    validates_inclusion_of    "design_#{attr}_unit", :in => DesignWidthUnits
  end

  validates_length_of :site_title,       :in => 1..64
  validates_length_of :site_keywords,    :in => 0..255
  validates_length_of :site_description, :in => 0..255
  validates_length_of :site_copyright,   :in => 0..64

  # SMTP settings
  validates_presence_of     :smtp_address
  validates_numericality_of :smtp_port, :only_integer => true, :allow_nil => false
  validates_inclusion_of    :smtp_port, :in => 1..65536
  validates_inclusion_of    :smtp_authentication, :in => %w(plain login cram_md5), :allow_nil => true

  # Get instance
  def self.instance
    self.find(Id)
  end

  # Get attribtute value
  def self.[](attr)
    self.instance[attr]
  end

  # Get the default(Site Wide) value of widget container width
  def self.container_width()
    "#{self[:design_width]}#{self[:design_width_unit]}"
  end

  # Get the default(Site Wide) value of left container width
  def self.left_container_width()
    "#{self[:design_lwidth]}#{self[:design_lwidth_unit]}"
  end

  # Get the default(Site Wide) value of right container width
  def self.right_container_width()
    "#{self[:design_rwidth]}#{self[:design_rwidth_unit]}"
  end

  # Update action mailer configuraiton following to the WjConfig data.
  def update_action_mailer
    settings = {}
    [:address, :port, :domain, :user_name, :password].each do |key|
      if self["smtp_#{key}"]
        value = self["smtp_#{key}"]
        settings[key] = value
      end
    end
    settings[:authentication] = self["smtp_authentication"].to_sym if self.smtp_authentication

    if settings[:user_name].blank? || settings[:password].blank? || settings[:authentication].blank?
      settings[:user_name] = nil
      settings[:password] = nil
      settings[:authentication] = :plain
    end

    logger.wj_debug "[Update ActionMailer] #{settings.inspect}"
    ActionMailer::Base.smtp_settings = settings
  end

  def http_class
    Net::HTTP
    #
    # TODO http class configuration
    #
    #if self.http_proxy_host.blank?
    #else
    #  Net::HTTP.Proxy(self.http_proxy_host,
    #                  self.http_proxy_port.
    #                  self.http_proxy_user.blank? ? nil : self.http_proxy_user,
    #                  self.http_proxy_user.blank? ? nil : self.http_proxy_password?)
    #end
  end
end
