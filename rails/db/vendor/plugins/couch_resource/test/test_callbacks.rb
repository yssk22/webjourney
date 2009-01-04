require 'test/unit'
require File.join(File.dirname(__FILE__), "../lib/couch_resource")
TEST_DB_PATH  = "/couch_resource_callback_test"

class CallbackOrderTest < CouchResource::Base
  self.database = "http://localhost:5984/#{TEST_DB_PATH}"
  string :title
  def callback_orders
    @callback_orders ||= []
  end
  CouchResource::Callbacks::CALLBACKS.each do |callback|
    module_eval "def #{callback}; callback_orders << :#{callback}; end"
  end
end

class StopCallbackTest < CouchResource::Base
  self.database = "http://localhost:5984/#{TEST_DB_PATH}"
  string :stopper_method
  def called_callbacks
    @called_callbacks ||= []
  end
  [:before_validation, :before_validation_on_create, :before_validation_on_update,
   :before_save,       :before_create, :before_update, :before_destroy].each do |callback|
    module_eval <<-EOS
     def #{callback};
       called_callbacks << :#{callback}
       return false if self.stopper_method.to_s == "#{callback}"
     end
EOS

  end

end

class TestValidations < Test::Unit::TestCase
  def setup
    res = CallbackOrderTest.connection.put(CallbackOrderTest.database.path)
    unless res[:ok]
      puts "Failed to create test database. Check couchdb server running."
    end
  end

  def teardown
    res = CallbackOrderTest.connection.delete(CallbackOrderTest.database.path)
    unless res[:ok]
      puts "Failed to drop test database. Delete manually before you test next time."
    end
  end

  def test_callback_order
    obj = CallbackOrderTest.new

    # after_initialize
    assert_equal [:after_initialize], obj.callback_orders
    obj.callback_orders.clear

    # validate and save callbacks
    obj.title = "hoge"
    assert obj.save
    assert_not_nil obj.callback_orders
    assert_equal [:before_validation, :before_validation_on_create,
                  :after_validation,  :after_validation_on_create,
                  :before_save,       :before_create,
                  :after_create,      :after_save],  obj.callback_orders
    obj.callback_orders.clear
    assert obj.save
    assert_equal [:before_validation, :before_validation_on_update,
                  :after_validation,  :after_validation_on_update,
                  :before_save,       :before_update,
                  :after_update,      :after_save],  obj.callback_orders
    obj.callback_orders.clear

    # after_find
    obj2 = CallbackOrderTest.find(obj.id)
    assert_equal [:after_initialize, :after_find], obj2.callback_orders
    obj2.callback_orders.clear

    # destroy
    assert obj.destroy
    assert_equal [:before_destroy, :after_destroy],  obj.callback_orders
  end

  def test_stop_callback
    obj = StopCallbackTest.new

    befores = [:before_validation, :before_validation_on_create,
               :before_save,       :before_create]

    befores.each_with_index do |stopper, index|
      obj.stopper_method = stopper
      assert !obj.save, "unexpected saving not working stopper (#{stopper})"
      assert_equal befores[0..index], obj.called_callbacks
      obj.called_callbacks.clear
    end

    obj.stopper_method = nil
    assert obj.save
    obj.called_callbacks.clear

    befores = [:before_validation, :before_validation_on_update,
               :before_save,       :before_update]
    befores.each_with_index do |stopper, index|
      obj.stopper_method = stopper
      assert !obj.save, "unexpected saving not working stopper (#{stopper})"
      assert_equal befores[0..index], obj.called_callbacks
      obj.called_callbacks.clear
    end

    obj.called_callbacks.clear
    obj.stopper_method = :before_destroy
    assert !obj.destroy
    assert_not_nil obj.rev
    assert_equal [:before_destroy],  obj.called_callbacks
  end
end
