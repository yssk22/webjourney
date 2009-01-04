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
