#
# WjUser class is an abstract ActiveRecord model for the account data.
# The WjUser subclasses automatically detected by the single table inheritance mechanism of ActiveRecord.
#
# - WjUser::LocalDB               : The user account authenticated by the local database password.
# - WjUser::OpenID                : The user account authenticated by the OpenID uri.
# - WjUser::BuiltIn:Administrator : Built in account for the administrator
# - WjUser::BuiltIn:Anonymous     : Built in account for the anonymous user.
#
# == Relationships and Properties
# === Relationships
#
# <tt>wj_roles</tt>:: has_and_belong_to_many for WjRole
#
# === Properties
#
# ==== Common properties
#
# <tt>login_name</tt>::   (r)  name to identify the user.
# <tt>display_name</tt>:: (rw) name to display on the HTML.
# <tt>type</tt>::         (r)  type string used by STI.
# <tt>status</tt>         (rw) status value.
# <tt>email</tt>          (rw)
# <tt>last_login_at</tt>  (rw) timespamp on last login.
# <tt>created_at</tt>     (rw)
# <tt>updated_at</tt>     (rw)
#
class WjUser < ActiveRecord::Base
  class InvalidStatusError  < WebJourney::Errors::ApplicationError # :nodoc:
  end

  # Status key-value pairs.
  Status = {
    :unknown   => 0,
    :prepared  => 1,
    :active    => 2,
    :locked    => 3,
    :destroyed => 4
  }

  has_and_belongs_to_many :wj_roles

  validates_format_of     :login_name, :with => /^[a-z][a-z0-9_]{1,15}$/, :allow_nil => false
  validates_uniqueness_of :login_name, :allow_nil => false
  validates_length_of     :display_name, :within => 0..16, :allow_nil => true
  attr_readonly           :login_name, :type
  attr_accessible         :display_name

  # Returns the number of users whose status is <tt>status</tt>.
  def self.number_of(status)
    self.count(:conditions => ["status = ?", WjUser::Status[status]])
  end

  # Returns the number of users whose status is <tt>:active</tt>.
  def self.number_of_active_user
    self.number_of(:active)
  end

  # Returns the list of accounts who match the <tt>filter_options</tt> as follows:
  #
  # - <tt>:starts_with</tt> the start characters of the login name (default: 'a')
  # - <tt>:class</tt>       the sub class of WjUser or WjUser itself (default : WjUser).
  # - <tt>:status</tt>      the status of the account (default 0, which means all)
  #
  # <tt>options</tt> are passed to the second args of <tt>find</tt> method.
  #
  # ==== Examples
  #
  # Get a list of active OpenID users each of whome starts with 'a'
  #
  #   WjUser.list(:starts_with => "a", :class => WjUser::OpenID, :status => Status[:active] )
  #
  # Get a list of active LocalDB users
  #
  #   WjUser.list(:class => WjUser::OpenID, :status => Status[:active] )
  #
  # Get a list of active users
  #
  #   WjUser.list(:status => Status[:active] )
  #
  def self.list(filter_options = {}, options = {})
    klass = filter_options[:class] || self
    cond_statement =  ["wj_users.login_name LIKE ?"]
    cond_params    =  [filter_options[:starts_with] =~ /^([a-z][a-z0-9_]*)$/ ? "#{$1}%" : "a%"]
    if filter_options[:status]
      cond_statement << ["wj_users.status = ?"]
      cond_params  << filter_options[:status]
    end
    options[:order] ||= "wj_users.login_name"
    klass.find(:all, options.merge({:conditions => [cond_statement.join(" AND "), cond_params].flatten}))
  end

  # Returns true if the <tt>status</tt> is <tt>:active</tt>.
  def is_active?
    self.status == WjUser::Status[:active]
  end
  alias :active? :is_active?

  # Returns true if the user is WjUser::BuiltIn::Administrator
  def is_administrator?
    self.is_a?(WjUser::BuiltIn::Administrator)
  end
  alias :administrator? :is_administrator?

  # Returns true if the user is WjUser::BuiltIn::Anonymous
  def is_anonymous?
    self.is_a?(WjUser::BuiltIn::Anonymous)
  end
  alias :anonymous? :is_anonymous?

  # Returns the <tt>display_name</tt> value, or <tt>login_name</tt> value if it is blank,
  def display_name
    self[:display_name] || self.login_name
  end

  # A interface method to process authentication with the specified <tt>credentials</tt>.
  # The <tt>credentials</tt> depends on the method, <tt>process_authentication</tt> defined in child classes.
  def authenticate(credentials)
    if self.is_active?
      if process_authenticate(credentials)
        logger.wj_info("User Authentication succeeded (#{self.login_name})")
        self.update_attribute(:last_login_at, Time.now)
        true
      else
        logger.wj_info("User Authentication failed : password mismatched (#{self.login_name})")
        false
      end
    else
      logger.wj_info("User Authentication failed : not active user (#{self.login_name})")
      false
    end
  end
  alias :login :authenticate


  # Returns the boolean value whether the user has <tt>role_names</tt>(symbol list).
  # <tt>options</tt> are:
  #   - :any - if set true, this method returns true when the user has any of the <tt>role_names</tt> (default: false).
  #
  # ==== Example
  #
  #   joe.has_roles?(:user)                          # true when joe has the 'user' role.
  #   joe.has_roles?(:user, :blogger)                # true when joe has the 'user' role <strong>and</strong> the 'blogger' role.
  #   joe.has_roles?(:user, :blogger, :any => true)  # true when joe has the 'user' role <strong>or</strong> the 'blogger' role.
  #
  def has_roles?(*role_names)
    return false if self.anonymous?
    return true  if self.administrator?
    option = role_names.extract_options!
    return true  if role_names.length == 0
    count = self.wj_roles.count(:conditions => ["wj_roles.name in (?)", role_names.map(&:to_s)])
    if option[:any]
      count > 0
    else
      count == role_names.length
    end
  end

  # profile methods are delegated
  delegate :related_to?, :to => "profile"

  # Returns the WjUser::Profile object related to the user.
  def profile(reload = false)
    if @profile.nil? || reload
      begin
        @profile = WjUser::Profile.find(self.login_name)
      rescue CouchResource::ResourceNotFound
        @profile = WjUser::Profile.new(:_id => self.login_name)
      end
    end
    @profile
  end

  # Return the status symbol, one of (:unknown, :prepared, :acctive, :locked or :destroyed)
  def status_string
    WjUser::Status.keys[WjUser::Status.values.index(self.status)]
  end

  protected
  # This method should be implemented in the child class.
  def process_authenticate(credentials)
    raise WebJourney::Errors::ApplicationError.new("The child class of WjUser must implement the process_authenticate method.")
  end
end
