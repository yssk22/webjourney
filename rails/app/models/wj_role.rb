class WjRole < ActiveRecord::Base
  has_and_belongs_to_many :wj_users

  def self.order_by_name
    WjRole.find(:all, :order => "name")
  end

  def self.defaults
    WjRole.find(:all, :conditions => ["is_default = ?", true])
  end

  def self.not_defaults
    WjRole.find(:all, :conditions => ["is_default = ?", false])
  end

  # Update default roles
  def self.update_default_roles(default_role_ids)
    WjRole.transaction do
      WjRole.update_all(["is_default = ?", true],
                        ["wj_roles.id IN (?)", default_role_ids])
      WjRole.update_all(["is_default = ?", false],
                        ["wj_roles.id NOT IN (?)", default_role_ids])
    end
  end
end
