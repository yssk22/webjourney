class WjUser < ActiveRecord::Base
  has_and_belongs_to_many :wj_roles

  validates_format_of     :login_name, :with => /^[a-z][a-z0-9_]{1,15}$/, :allow_nil => false
  validates_uniqueness_of :login_name, :allow_nil => false
  validates_length_of     :display_name, :within => 0..16, :allow_nil => true
  attr_readonly           :login_name, :type
  attr_accessible         :display_name
  # attr_protected :email, :uri, :open_id_uri
  # attr_protected :status, :last_login_at, :password_hash
  # attr_protected :request_passcode, :request_key, :request_value, :request_at

  class InvalidStatusError  < WebJourney::Errors::ApplicationError # :nodoc:
  end

  # hash of Status integer values
  Status = {
    :unknown   => 0,
    :prepared  => 1,
    :active    => 2,
    :locked    => 3,
    :destroyed => 4
  }

  def self.number_of(status)
    self.count(:conditions => ["status = ?", WjUser::Status[status]])
  end

  def self.number_of_active_user
    self.number_of(:active)
  end

  # List the accounts
  #
  # <tt>filter_options</tt> are filter parameters as follows:
  #  :starts_with - the start characters of the login name. (default: 'a')
  #  :class       - the sub class of WjUser or WjUser itself (default : WjUser).
  #  :status      - the status of the account. (default 0, which means all)
  #
  # <tt>options</tt> are passed to the second args of find(:all, options)
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

  # Get whether the user is active or not.
  def is_active?
    self.status == WjUser::Status[:active]
  end
  alias :active? :is_active?

  # Get whether the user is administrator or not.
  def is_administrator?
    self.is_a?(WjUser::BuiltIn::Administrator)
  end
  alias :administrator? :is_administrator?

  # Get whether the user is anonymous or not.
  def is_anonymous?
    self.is_a?(WjUser::BuiltIn::Anonymous)
  end
  alias :anonymous? :is_anonymous?

  def display_name
    self[:display_name] || self.login_name
  end

  # Execute authentication with the specified credentials
  # The child class must implement the <tt>process_authenticate</tt> method to work correctly.
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


  # Get the boolean value whether the user has <tt>role_names</tt>.
  # <tt>options</tt> are:
  #   - :any - if set true, this method returns true when the user has any of the <tt>role_names</tt>. (default: false)
  #
  # example)
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

  # Get the user profile
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

  def status_string
    WjUser::Status.keys[WjUser::Status.values.index(self.status)]
  end

  protected
  def process_authenticate(credentials)
    raise WebJourney::Errors::ApplicationError.new("The child class of WjUser must implement the process_authenticate method.")
  end
end
