#
# WjRole class is an ActiveRecord model for the user roles.
#
# == Relationships and Properties
# === Relationships
#
# <tt>wj_roles</tt>:: has_and_belong_to_many for WjUser
#
# === Properties
#
# <tt>name</tt>::       (r)
# <tt>is_default</tt>:: (rw)
# <tt>type</tt>::       (r)
# <tt>created_at</tt>:: (r)
# <tt>updated_at</tt>:: (r)
class WjRole < ActiveRecord::Base
  has_and_belongs_to_many :wj_users

  SERIALIZE_METHOD_DEFAULTS  = [:type_string]
  SERIALIZE_EXCLUDE_DEFAULTS = []

  # Returns all roles orderd by the name property.
  def self.order_by_name
    WjRole.find(:all, :order => "name")
  end

  # Returns default roles
  def self.defaults
    WjRole.find(:all, :conditions => ["is_default = ?", true])
  end

  # Returns not-default roles
  def self.not_defaults
    WjRole.find(:all, :conditions => ["is_default = ?", false])
  end

  # Update <tt>is_default</tt> values.
  def self.update_default_roles(default_role_ids)
    WjRole.transaction do
      WjRole.update_all(["is_default = ?", true],
                        ["wj_roles.id IN (?)", default_role_ids])
      WjRole.update_all(["is_default = ?", false],
                        ["wj_roles.id NOT IN (?)", default_role_ids])
    end
  end

  # Returns the type short string
  def type_string
    self.type.underscore.split("/").last
  end

  # Returns JSON representation
  def to_json(options={})
    options[:methods] = SERIALIZE_METHOD_DEFAULTS  unless options.has_key?(:methods)
    options[:except]  = SERIALIZE_EXCLUDE_DEFAULTS unless options.has_key?(:except)
    super(options)
  end

end
