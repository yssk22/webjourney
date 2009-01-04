module WebJourney
  class RelationshipAllowList < CouchResource::SubResource
    boolean :all
    array   :tags
    alias :tags_org :tags

    def tags
      self.tags = [] unless self.tags_org
      self.tags_org
    end
  end

  module Acts
    module RelationshipPermittable
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_relationship_permittable(defaults = {}, option = {})
          include WebJourney::Acts::RelationshipPermittable::InstanceMethods
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


      module InstanceMethods
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

CouchResource::Base.send :include, WebJourney::Acts::RelationshipPermittable
