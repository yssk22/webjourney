require 'rubygems'
require 'json'

module CouchResource
  # Callbacks are hooks similar to ActiveRecord::Callbacks
  #
  # * (-) <tt>save</tt>
  # * (-) <tt>valid</tt>
  # * (1) <tt>before_validation</tt>
  # * (2) <tt>before_validation_on_create</tt>
  # * (-) <tt>validate</tt>
  # * (-) <tt>validate_on_create</tt>
  # * (3) <tt>after_validation</tt>
  # * (4) <tt>after_validation_on_create</tt>
  # * (5) <tt>before_save</tt>
  # * (6) <tt>before_create</tt>
  # * (-) <tt>create</tt>
  # * (7) <tt>after_create</tt>
  # * (8) <tt>after_save</tt>
  #
  module Callbacks
    CALLBACKS = %w(
      after_find after_initialize before_save after_save before_create after_create before_update after_update before_validation
      after_validation before_validation_on_create after_validation_on_create before_validation_on_update
      after_validation_on_update before_destroy after_destroy
    )

    def self.included(base)
      [:create_or_update, :valid?, :create, :update, :destroy].each do |method|
        base.send :alias_method_chain, method, :callbacks
      end

      base.send(:include, ActiveSupport::Callbacks)
      [:save, :create, :update, :validation, :validation_on_create, :validation_on_update, :destroy].each do |method|
        base.define_callbacks "before_#{method}".to_sym,  "after_#{method}".to_sym
      end

    end

    [:save, :create, :update, :validation, :validation_on_create, :validation_on_update, :destroy].each do |method|
      module_eval <<-EOS
      def before_#{method}; end
      def after_#{method};  end
EOS
    end

    private
    def create_or_update_with_callbacks
      return false if invoke_callbacks(:before_save) == false
      result = create_or_update_without_callbacks
      invoke_callbacks(:after_save)
      result
    end

    def create_with_callbacks
      return false if invoke_callbacks(:before_create) == false
      result = create_without_callbacks
      invoke_callbacks(:after_create)
      result
    end

    def update_with_callbacks
      return false if invoke_callbacks(:before_update) == false
      result = update_without_callbacks
      invoke_callbacks(:after_update)
      result
    end

    def valid_with_callbacks?
      return false if invoke_callbacks(:before_validation) == false
      if new_record? then
        return false if invoke_callbacks(:before_validation_on_create) == false
      else
        return false if invoke_callbacks(:before_validation_on_update) == false
      end

      result = valid_without_callbacks?

      invoke_callbacks(:after_validation)
      if new_record? then
        invoke_callbacks(:after_validation_on_create)
      else
        invoke_callbacks(:after_validation_on_update)
      end
      return result
    end

    def destroy_with_callbacks
      return false if invoke_callbacks(:before_destroy) == false
      result = destroy_without_callbacks
      invoke_callbacks(:after_destroy)
      result
    end

    def invoke_callbacks(callback_name)
      # invoke member method
      return false if send(callback_name) == false
      # invoke callbacks defined by using ActiveSupport::Callbacks
      run_callbacks(callback_name)
    end

  end
end
