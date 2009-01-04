require 'rubygems'
require 'active_support'
require 'json'
module CouchResource
  module Struct
    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
    end

    module ClassMethods
      #
      # define a string attribtue
      # options are :
      # * <tt>:validates</tt> - see CouchResource::Validations
      #
      def string(name, option={})
        option[:is_a] = :string
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        define_validations(name, option)
      end

      #
      # define a number attribute
      # options are :
      # * <tt>:validates</tt> - see CouchResource::Validations
      #
      def number(name, option={})
        option[:is_a] = :number
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        define_validations(name, option)
      end

      #
      # define a boolean attribute
      # options are :
      # * <tt>:validates</tt> - see CouchResource::Validations
      #
      def boolean(name, option={})
        option[:is_a] = :boolean
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        method = <<-EOS
          def #{name}?
            get_attribute(:#{name})
          end
EOS
        class_eval(method, __FILE__, __LINE__)
        define_validations(name, option)
      end

      #
      # define a array attribute, each of which elements is a primitive (one of string, number, array, boolean or hash) object
      # options are :
      #
      def array(name, option={})
        option[:is_a] = :array
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        define_validations(name, option)
      end

      #
      # define a collection attribute, each of which elements is an object specified by the <tt>:is_a</tt> option.
      # options are :
      # * <tt>:each</tt> - set the class to encode/decode each of Hash object (default is :hash, which means no encoding/decoding will be processed)
      # * <tt>:validates</tt> - see CouchResource::Validations
      #
      def collection(name, option={})
        option = {
          :each => :hash
        }.update(option)
        option[:is_a] = :collection
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        define_validations(name, option)
      end

      #
      # define a object attribute
      # <tt>options</tt> are :
      # * <tt>:is_a</tt> - set the class to encode/decode Hash object (default is :hash, which means no encoding/decoding will be processed)
      # * <tt>:validates</tt> - see CouchResource::Validations
      #
      def object(name, option={})
        unless option.has_key?(:is_a)
          option[:is_a] = :hash
        end
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        define_validations(name, option)
      end

      #
      # define a datetime object (extension of string)
      # options are :
      # * <tt>:validates</tt> - see CouchResource::Validations
      #
      def datetime(name, option={})
        option[:is_a] = :datetime
        register_attribute_member(name, option)
        define_attribute_accessor(name, option)
        define_validations(name, option)
      end


      def from_hash(hash)
        hash ||= {}
        hash.symbolize_keys!
        instance = self.new
        (read_inheritable_attribute(:attribute_members) || {}).each do |name, option|
          instance.set_attribute(name, hash[name.to_sym])
        end
        instance
      end

      private
      def register_attribute_member(name, option = {})
        attribute_members = read_inheritable_attribute(:attribute_members)
        attribute_members ||= HashWithIndifferentAccess.new({})
        attribute_members[name] = option
        write_inheritable_attribute(:attribute_members, attribute_members)
      end

      def define_attribute_accessor(name, option={})
        define_attribute_read_accessor(name, option)
        define_attribute_write_accessor(name, option)
      end

      def define_attribute_read_accessor(name, option={})
        method = <<-EOS
          def #{name}
            get_attribute(:#{name})
          end
          def #{name}_before_type_cast
            get_attribute_before_type_cast(:#{name})
          end
EOS
        class_eval(method, __FILE__, __LINE__)
      end

      def define_attribute_write_accessor(name, option={})
        method = <<-EOS
          def #{name}=(value)
            set_attribute(:#{name}, value)
          end
EOS
        class_eval(method, __FILE__, __LINE__)
      end

      def define_validations(name, option={})
        (option[:validates] || []).each do |validation_type, validate_option|
          args = validate_option.nil? ? [name] : [name, validate_option]
          case validation_type.to_sym
          when :each
            proc = validate_option[:proc]
            send("validates_each", *args) do |record, attr, value|
              proc.call(record, attr, value) if proc
            end
          when :confirmation_of, :presense_of, :length_of, :size_of, :format_of,
            :inclusion_of, :exclusion_of, :numericality_of, :children_of
            send("validates_#{validation_type}", *args)
          else
            raise ArgumentError, "invalid validation type (#{validation_type})"
          end
        end
      end
    end

    module InstanceMethods
      def [](name)
        get_attribute(name)
      end

      def []=(name, value)
        set_attribute(name, value)
      end

      def get_attribute_option(attr_name)
        (self.class.read_inheritable_attribute(:attribute_members) || {})[attr_name]
      end

      def set_attribute(name, value)
        @attributes ||= HashWithIndifferentAccess.new({})
        # inplicit type cast
        attribute_members = self.class.read_inheritable_attribute(:attribute_members) || {}
        if attribute_members.has_key?(name)
          option = attribute_members[name]
          if value.nil?
            @attributes[name] = nil
          else
            if option[:allow_nil] && value.blank?
              @attributes[name] = nil
            else
              klass = option[:is_a]
              @attributes[name] = case klass
                                  when :string, :number, :boolean, :array, :hash, :datetime
                                    self.send("type_cast_for_#{klass}_attributes", value)
                                  when :collection
                                    self.send("type_cast_for_collection_attributes", value, option[:each])
                                  else
                                    self.send("type_cast_for_object_attributes", value, klass)
                                  end
            end
          end
        else
          @attributes[name] = nil
        end
        value
      end


      def get_attribute(name)
        value = get_attribute_before_type_cast(name)
        attribute_members = self.class.read_inheritable_attribute(:attribute_members) || {}
        if attribute_members.has_key?(name)
          value = @attributes[name]
          option = attribute_members[name]
          value
          #if value.nil?
          #  nil
          #else
          #  klass = option[:is_a]
          #  case klass
          #  when :string, :number, :boolean, :array, :hash, :datetime
          #    self.send("type_cast_for_#{klass}_attributes", value)
          #  when :collection
          #    self.send("type_cast_for_collection_attributes", value, option[:each])
          #  else
          #    self.send("type_cast_for_object_attributes", value, klass)
          #  end
          #end
        else
          nil
        end
      end

      def get_attribute_before_type_cast(name)
        @attributes ||= HashWithIndifferentAccess.new({})
        @attributes[name]
      end

      def to_hash
        hash = HashWithIndifferentAccess.new({ :class => self.class.name })
        (self.class.read_inheritable_attribute(:attribute_members) || {}).each do |name, option|
          klass = option[:is_a]
          value = get_attribute(name)
          case klass
          when :string, :number, :boolean, :array, :hash, :datetime
            hash[name] = value
          when :collection
            hash[name] = value.map(&:to_hash)
          else
            if value
              hash[name] = value.to_hash
            else
              hash[name] = nil
            end
          end
        end
        hash
      end

      private
      def type_cast_for_string_attributes(value)
        value.is_a?(String) ? value : value.to_s
      end

      def type_cast_for_number_attributes(value)
        if value.is_a?(Numeric)
          value
        else
          v = value.to_s
          if v =~ /^\d+$/
            v.to_i
          else
            v.to_f
          end
        end
      end

      def type_cast_for_boolean_attributes(value)
        value && true
      end

      def type_cast_for_array_attributes(value)
        if value.is_a?(Array)
          value
        else
          if value.respond_to?(:to_a)
            value.to_a
          else
            [value]
          end
        end
      end

      def type_cast_for_collection_attributes(v1, each)
        type_cast_for_array_attributes(v1).map { |v2|
          type_cast_for_object_attributes(v2, each)
        }.reject { |v3|
          v3.nil?
        }
      end

      def type_cast_for_hash_attributes(value)
        if value.is_a?(Hash)
          value
        else
          if value.respond_to?(:to_hash)
            value.to_hash
          else
            nil
          end
        end
      end

      def type_cast_for_object_attributes(value, klass)
        if value.is_a?(klass)
          value
        elsif value.is_a?(Hash)
          klass.from_hash(value)
        else
          nil
        end
      end

      def type_cast_for_datetime_attributes(value)
        case value
        when Date, Time, DateTime
          value
        else
          DateTime.parse(value.to_s) rescue nil
        end
      end
    end
  end
end
