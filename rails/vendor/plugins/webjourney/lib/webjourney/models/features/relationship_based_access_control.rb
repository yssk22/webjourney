module WebJourney
  class RelationshipAllowList < CouchResource::SubResource # :nodoc:
    boolean :all
    array   :tags
    alias :tags_org :tags

    def tags
      self.tags = [] unless self.tags_org
      self.tags_org
    end
  end

  module Features # :nodoc:
    module RelationshipBasedAccessControl # :nodoc:
      def self.included(base)
        super
        base.send :extend,  ClassMethods
        base.send :include, InstanceMethods
      end

      module ClassMethods
        #
        # Append the Relationship based ACL feature to CouchResource models.
        # It is easy to hanle relationship based accesss control using <tt>acts_as_relationship_permittable</tt>
        #
        # === Relationship based ACL feature
        #
        # A CouchResource object can have a property named <tt>relationship_keys</tt> to manage access control whitelist.
        # The <tt>relationship_keys</tt> is a (key, value) pairs as a list of
        # Here is a json hash format example ::
        #
        #   relationship_keys : {
        #      key1: {
        #         all  : true
        #         tags : []
        #      },
        #      key2: {
        #         all  : false
        #         tags : ["friend", "colleague"]
        #      },
        #      key3: {
        #         all  : false
        #         tags : ["family"]
        #      },
        #      ...
        #   }
        #
        # <tt>key</tt> is a action name and <tt>value</tt> is a hash which contains <tt>all</tt> and <tt>tags</tt> values.
        #
        # - <tt>all</tt> means whether the action is permited to all users or not.
        # - <tt>tags</tt> is a user tag list to whom the action is permited.
        #
        # These properties can be accessed via  WebJourney::RelationshipAllowList
        # To check the ACL, use allow_key1(), allow_key2(), allow_key3(), ... methods.
        # <tt>acts_as_relationship_permittable</tt> method defines allow_{keyname}?(user) method to check accessibility for the <tt>user</tt>.
        #
        # === Example
        #
        #   class WjPage < CouchResource::Base
        #     acts_as_relationship_permittable({
        #                             :show => {:all => true,  :tags => []},
        #                             :edit => {:all => false, :tags => []}
        #                           })
        #     ...
        #   end
        #
        # This example show you that:
        #
        # - WjPage has two relationship based access control keys, <tt>:show</tt> and <tt>:edit</tt>
        # - The default ACL is as follows::
        #   - allow <tt>:show</tt> to all users.
        #   - deny  <tt>:edit</tt> to all users.
        #
        # The <tt>acts_as_relationship_permittable</tt> defines methods to check access control list. Here is this.
        #
        #   page = WjPage.create_new
        #   page.allow_show?(user)
        #   # => true
        #   page.allow_edit?(user)
        #   # => false
        #
        #   # change ACL
        #   page.relationship_keys.show.all  = false
        #   page.relationship_keys.show.tags = ["friends"]
        #
        #   page.allow_show?(user)
        #   # => false
        #
        #   # allow_key=(option) method can be used to change ACL
        #   page.allow_show(:all => true, :tags => [])
        #
        def acts_as_relationship_permittable(defaults = {}, option = {})
          attr = :relationship_keys
          option.symbolize_keys!
          option = {
          }.update(option)

          defaults.symbolize_keys!
          klass_name = attr.to_s.camelize
          allow_list = defaults.map { |key, default|
              "object :#{key}, :is_a => WebJourney::RelationshipAllowList"
          }.join(";")
          define = <<-EOS
          class #{klass_name} < CouchResource::SubResource
            #{allow_list}
          end
EOS
          class_eval(define, __FILE__, __LINE__)
          relationshipClass = "#{self.name}::#{klass_name}".constantize
          defaultRelationshipKeys = relationshipClass.from_hash(defaults)

          object attr, :is_a => relationshipClass, :default => defaultRelationshipKeys.dup

          # define allow_xxx methods
          defaults.each do |key, default|
            define = <<-EOS
            def allow_#{key}?(user)
              self.permit_relationship_of?(user, :#{key})
            end
            def allow_#{key}(options={})
              options.symbolize_keys!
              self.relationship_keys.#{key}.all  = (options[:all] == true) if options.has_key?(:all)
              self.relationship_keys.#{key}.tags = options[:tags]          if options.has_key?(:tags)
            end
EOS
            class_eval(define, __FILE__, __LINE__)
          end
        end
      end

      module InstanceMethods # :nodoc:
        def permit_relationship_of?(user, key)
          owner_login_name = self.owner_login_name
          return true if owner_login_name == user.login_name
          key = self.relationship_keys[key]
          if key
            return true if key.all
            owner = WjUser.find_by_login_name(owner_login_name)
            key.tags.each do |tag|
              return true if owner.related_to?(user, tag)
            end
            return false
          else
            false
          end
        end
      end
    end
  end
end

CouchResource::Base.send :include, WebJourney::Features::RelationshipBasedAccessControl
