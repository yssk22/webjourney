#
# This file is based on active_record/validations.rb (ActiveRecord 2.1.0)
# and customize some sentences to work as CouchResource validations.
#
require File.join(File.dirname(__FILE__), "struct")
require File.join(File.dirname(__FILE__), "error")

module CouchResource

  # Raised by save! and create! when the record is invalid.
  # Use the record method to retrieve the record which did not validate.
  class RecordInvalid < CouchResourceError
    attr_reader :record
    def initialize(record)
      @record = record
      super("Validation failed: #{@record.errors.full_messages.join(", ")}")
    end
  end

  # CouchResource::Errors is the completely same as ActiveRecord::Errors
  class Errors
    include Enumerable

    def initialize(base) # :nodoc:
      @base, @errors = base, {}
    end

    @@default_error_messages = {
      :inclusion => "is not included in the list",
      :exclusion => "is reserved",
      :invalid => "is invalid",
      :confirmation => "doesn't match confirmation",
      :accepted  => "must be accepted",
      :empty => "can't be empty",
      :blank => "can't be blank",
      :too_long => "is too long (maximum is %d characters)",
      :too_short => "is too short (minimum is %d characters)",
      :wrong_length => "is the wrong length (should be %d characters)",
      :taken => "has already been taken",
      :not_a_number => "is not a number",
      :greater_than => "must be greater than %d",
      :greater_than_or_equal_to => "must be greater than or equal to %d",
      :equal_to => "must be equal to %d",
      :less_than => "must be less than %d",
      :less_than_or_equal_to => "must be less than or equal to %d",
      :odd => "must be odd",
      :even => "must be even",
      :children => "is not valid"  # append for object or array
    }

    cattr_accessor :default_error_messages

    def add_to_base(msg)
      add(:base, msg)
    end

    def add(attribute, msg = @@default_error_messages[:invalid])
      @errors[attribute.to_s] = [] if @errors[attribute.to_s].nil?
      @errors[attribute.to_s] << msg
    end

    def add_on_empty(attributes, msg = @@default_error_messages[:empty])
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        is_empty = value.respond_to?("empty?") ? value.empty? : false
        add(attr, msg) unless !value.nil? && !is_empty
      end
    end

    def add_on_blank(attributes, msg = @@default_error_messages[:blank])
      for attr in [attributes].flatten
        value = @base.respond_to?(attr.to_s) ? @base.send(attr.to_s) : @base[attr.to_s]
        add(attr, msg) if value.blank?
      end
    end

    def invalid?(attribute)
      !@errors[attribute.to_s].nil?
    end

    def on(attribute)
      errors = @errors[attribute.to_s]
      return nil if errors.nil?
      errors.size == 1 ? errors.first : errors
    end

    alias :[] :on

    def on_base
      on(:base)
    end

    def each
      @errors.each_key { |attr| @errors[attr].each { |msg| yield attr, msg } }
    end

    def each_full
      full_messages.each { |msg| yield msg }
    end

    def full_messages
      full_messages = []

      @errors.each_key do |attr|
        @errors[attr].each do |msg|
          next if msg.nil?
          if attr == "base"
            full_messages << msg
          else
            full_messages << @base.class.human_attribute_name(attr) + " " + msg
          end
        end
      end
      full_messages
    end

    def empty?
      @errors.empty?
    end

    def clear
      @errors = {}
    end

    def size
      @errors.values.inject(0) { |error_count, attribute| error_count + attribute.size }
    end

    alias_method :count, :size
    alias_method :length, :size

    def to_xml(options={})
      options[:root]    ||= "errors"
      options[:indent]  ||= 2
      options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

      options[:builder].instruct! unless options.delete(:skip_instruct)
      options[:builder].errors do |e|
        
        full_messages.each { |msg| e.error(msg) }
      end
    end

    def to_json
      self.to_hash.to_json
    end

    def to_hash
      array = []
      @errors.each_key do |attr|
        @errors[attr].each do |msg|
          next if msg.nil?
          if attr == "base"
            array << { :message => msg }
          else
            array << {
              :message => @base.class.human_attribute_name(attr) + " " + msg,
              :attr    => attr
            }
          end
        end
      end
      { :errors => array }
    end
  end

  module Validations
    VALIDATIONS = %w( validate validate_on_create validate_on_update )

    def self.included(base)
      base.send(:extend,  ClassMethods)
      base.send(:include, InstanceMethods)
      base.send(:include, ActiveSupport::Callbacks)
      base.define_callbacks *VALIDATIONS
    end

    module ClassMethods
      DEFAULT_VALIDATION_OPTIONS = {
        :on => :save,
        :allow_nil => false,
        :allow_blank => false,
        :message => nil
      }.freeze

      ALL_RANGE_OPTIONS = [ :is, :within, :in, :minimum, :maximum ].freeze
      ALL_NUMERICALITY_CHECKS = {
        :greater_than => '>', :greater_than_or_equal_to => '>=',
        :equal_to => '==', :less_than => '<', :less_than_or_equal_to => '<=',
        :odd => 'odd?', :even => 'even?' }.freeze

      # This method is the same as ActiveRecord::Validations.validates_each(*attr)
      #
      #  class Person
      #   string :first_name, :validates => {
      #      [:each,{
      #         :proc => Proc.new do |record, attr, value|
      #            record.errors.add attr, "starts with z." if value[0] == ?z
      #         end
      #      }]
      #  end
      #
      # or
      #
      #  class Person
      #   string :first_name
      #   validates_each :first_name do  |record, attr, value|
      #     record.errors.add attr, "starts with z." if value[0] == ?z
      #   end
      #  end
      def validates_each(*attrs)
        options = attrs.extract_options!.symbolize_keys
        attrs   = attrs.flatten

        send(validation_method(options[:on] || :save), options) do |record|
          attrs.each do |attr|
            value = record.get_attribute(attr)
            next if (value.nil? && options[:allow_nil]) || (value.blank? && options[:allow_blank])
            yield record, attr, value
          end
        end
      end

      # This method is the same as ActiveRecord::Validations.vaildates_confirmation_of(*attr_names)
      #
      #   class Person
      #     string :password, :validates => [:confirmation_of]
      #   end
      #
      # or
      #
      #   class Person
      #     string :password
      #     validates_confirmation_of :password
      #   end
      def validates_confirmation_of(*attr_names)
        configuration = {
          :message => CouchResource::Errors.default_error_messages[:confirmation],
          :on => :save
        }
        configuration.update(attr_names.extract_options!)

        attr_accessor(*(attr_names.map { |n| "#{n}_confirmation" }))

        validates_each(attr_names, configuration) do |record, attr_name, value|
          unless record.send("#{attr_name}_confirmation").nil? or value == record.send("#{attr_name}_confirmation")
            record.errors.add(attr_name, configuration[:message])
          end
        end
      end

      # This method is the same as ActiveRecord::Validations.vaildates_confirmation_of(*attr_names)
      # This method is not implemented because the validator works for only virtual attributes.
      def validates_acceptance_of
        raise "Not Implemented"
      end

      # This method is the same as ActiveRecord::Validations.vaildates_presense_of(*attr_names)
      #
      #   class Person
      #     string :first_name, :validates => [:presense_of]
      #   end
      #
      # or
      #
      #   class Person
      #     string :first_name
      #     validates_presense_of :first_name
      #   end
      #
      def validates_presense_of(*attr_names)
        configuration = { :message => CouchResource::Errors.default_error_messages[:blank], :on => :save }
        configuration.update(attr_names.extract_options!)

        # can't use validates_each here, because it cannot cope with nonexistent attributes,
        # while errors.add_on_empty can
        send(validation_method(configuration[:on]), configuration) do |record|
          record.errors.add_on_blank(attr_names, configuration[:message])
        end
      end


      # This method is the same as ActiveRecord::Validations.vaildates_length_of(*attrs)
      #   class Person
      #     string :first_name, :validates => [
      #        [:lenfth_of, {:minimum => 1, :maximum => 16}]
      #     ]
      #   end
      #
      # or
      #
      #   class Person
      #     string :first_name
      #     validates_presense_of :first_name, :minumum => 1, :maximum => 16
      #   end
      def validates_length_of(*attrs)
        # Merge given options with defaults.
        options = {
          :too_long     => CouchResource::Errors.default_error_messages[:too_long],
          :too_short    => CouchResource::Errors.default_error_messages[:too_short],
          :wrong_length => CouchResource::Errors.default_error_messages[:wrong_length]
        }.merge(DEFAULT_VALIDATION_OPTIONS)
        options.update(attrs.extract_options!.symbolize_keys)

        # Ensure that one and only one range option is specified.
        range_options = ALL_RANGE_OPTIONS & options.keys
        case range_options.size
          when 0
            raise ArgumentError, 'Range unspecified.  Specify the :within, :maximum, :minimum, or :is option.'
          when 1
            # Valid number of options; do nothing.
          else
            raise ArgumentError, 'Too many range options specified.  Choose only one.'
        end

        # Get range option and value.
        option = range_options.first
        option_value = options[range_options.first]

        case option
          when :within, :in
            raise ArgumentError, ":#{option} must be a Range" unless option_value.is_a?(Range)

            too_short = options[:too_short] % option_value.begin
            too_long  = options[:too_long]  % option_value.end

            validates_each(attrs, options) do |record, attr, value|
              value = value.split(//) if value.kind_of?(String)
              if value.nil? or value.size < option_value.begin
                record.errors.add(attr, too_short)
              elsif value.size > option_value.end
                record.errors.add(attr, too_long)
              end
            end
          when :is, :minimum, :maximum
            raise ArgumentError, ":#{option} must be a nonnegative Integer" unless option_value.is_a?(Integer) and option_value >= 0

            # Declare different validations per option.
            validity_checks = { :is => "==", :minimum => ">=", :maximum => "<=" }
            message_options = { :is => :wrong_length, :minimum => :too_short, :maximum => :too_long }

            message = (options[:message] || options[message_options[option]]) % option_value

            validates_each(attrs, options) do |record, attr, value|
              value = value.split(//) if value.kind_of?(String)
              record.errors.add(attr, message) unless !value.nil? and value.size.method(validity_checks[option])[option_value]
            end
        end
      end

      alias_method :validates_size_of, :validates_length_of

      # This method is the same as ActiveRecord::Validations.vaildates_uniqueness_of(*attr_names)
      # This method is not implemented because you should define a new design document for validation of uniqueness to validate.
      def validates_uniqueness_of
        raise "Not Implemented"
      end

      # This method is the same as ActiveRecord::Validations.vaildates_format_of(*attr_names)
      def validates_format_of(*attr_names)
        configuration = { :message => CouchResource::Errors.default_error_messages[:invalid], :on => :save, :with => nil }
        configuration.update(attr_names.extract_options!)

        raise(ArgumentError, "A regular expression must be supplied as the :with option of the configuration hash") unless configuration[:with].is_a?(Regexp)

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message] % value) unless value.to_s =~ configuration[:with]
        end
      end

      # This method is the same as ActiveRecord::Validations.vaildates_inclusion_of(*attr_names)
      def validates_inclusion_of(*attr_names)
        configuration = { :message => CouchResource::Errors.default_error_messages[:inclusion], :on => :save }
        configuration.update(attr_names.extract_options!)

        enum = configuration[:in] || configuration[:within]

        raise(ArgumentError, "An object with the method include? is required must be supplied as the :in option of the configuration hash") unless enum.respond_to?("include?")

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message] % value) unless enum.include?(value)
        end
      end

      # This method is the same as ActiveRecord::Validations.vaildates_exclusion_of(*attr_names)
      def validates_exclusion_of(*attr_names)
        configuration = { :message => CouchResource::Errors.default_error_messages[:exclusion], :on => :save }
        configuration.update(attr_names.extract_options!)

        enum = configuration[:in] || configuration[:within]

        raise(ArgumentError, "An object with the method include? is required must be supplied as the :in option of the configuration hash") unless enum.respond_to?("include?")

        validates_each(attr_names, configuration) do |record, attr_name, value|
          record.errors.add(attr_name, configuration[:message] % value) if enum.include?(value)
        end
      end

      # This method is the same as ActiveRecord::Validations.vaildates_numericality_of(*attr_names)
      def validates_numericality_of(*attr_names)
        configuration = { :on => :save, :only_integer => false, :allow_nil => false }
        configuration.update(attr_names.extract_options!)


        numericality_options = ALL_NUMERICALITY_CHECKS.keys & configuration.keys

        (numericality_options - [ :odd, :even ]).each do |option|
          raise ArgumentError, ":#{option} must be a number" unless configuration[option].is_a?(Numeric)
        end

        validates_each(attr_names,configuration) do |record, attr_name, value|
          raw_value = record.send("#{attr_name}_before_type_cast") || value

          next if configuration[:allow_nil] and raw_value.nil?

          if configuration[:only_integer]
            unless raw_value.to_s =~ /\A[+-]?\d+\Z/
              record.errors.add(attr_name, configuration[:message] || ActiveRecord::Errors.default_error_messages[:not_a_number])
              next
            end
            raw_value = raw_value.to_i
          else
           begin
              raw_value = Kernel.Float(raw_value.to_s)
            rescue ArgumentError, TypeError
              record.errors.add(attr_name, configuration[:message] || ActiveRecord::Errors.default_error_messages[:not_a_number])
              next
            end
          end

          numericality_options.each do |option|
            case option
              when :odd, :even
                record.errors.add(attr_name, configuration[:message] || CouchResource::Errors.default_error_messages[option]) unless raw_value.to_i.method(ALL_NUMERICALITY_CHECKS[option])[]
              else
                message = configuration[:message] || CouchResource::Errors.default_error_messages[option]
                message = message % configuration[option] if configuration[option]
                record.errors.add(attr_name, message) unless raw_value.method(ALL_NUMERICALITY_CHECKS[option])[configuration[option]]
            end
          end
        end
      end

      # This method is original for CouchResource validation to validate child object in this class.
      #   class Person
      #     object :children, :is_a => Children, :validates => [
      #       [:children_of, {:on => :create, :allow_nil => true }]
      #     ]
      #   end
      def validates_children_of(*attr_names)
        configuration = { :message => CouchResource::Errors.default_error_messages[:children], :on => :save }
        configuration.update(attr_names.extract_options!)
        validates_each(attr_names, configuration) do |record, attr_name, value|
          if value.respond_to?(:valid?)
            record.errors.add(attr_name, configuration[:message] % value) unless value.valid?
          end
        end
      end

      private
      def validation_method(on)
        case on
        when :save   then :validate
        when :create then :validate_on_create
        when :update then :validate_on_update
        end
      end
    end

    module InstanceMethods
      def errors
        @errors ||= Errors.new(self)
      end

      def valid?
        errors.clear

        run_callbacks(:validate)
        validate
        # validate the object only which has #new? method.
        if respond_to?(:new?)
          if new?
            run_callbacks(:validate_on_create)
            validate_on_create
          else
            run_callbacks(:validate_on_update)
            validate_on_update
          end
        end

        errors.empty?
      end

      def save_with_validation(perform_validation=true)
        if perform_validation && valid? || !perform_validation
          save_without_validation
        else
          false
        end
      end

      def save_with_validation!
        if valid?
          save_without_validation!
        else
          raise RecordInvalid.new(self)
        end
      end

      protected
      def validate
      end

      def validate_on_create
      end

      def validate_on_update
      end
    end
  end
end
