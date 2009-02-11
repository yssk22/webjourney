module WebJourney
  # Unhandled error class raised by assertion failures.
  class AssertionFailedError < WebJourney::Errors::ApplicationError
  end

  module Assertion # :nodoc:
    #
    # This module defines assertion methods for ActiveRecord, CouchResource, ActionController.
    # If the assertion failed, AssertionFailureError is raised.
    #
    module Methods
      def assert_failure(msg=nil)
        assert(false, msg || "Force assertion to fail!!", 2)
      end

      def assert_true(boolean, msg = nil)
        assert(boolean && true, msg || "#{boolean} expected to be true.", 2)
      end

      def assert_false(boolean, msg = nil)
        assert(!(boolean && true), msg || "#{boolean}  expected to be false.", 2)
      end

      def assert_equal(expected, actual, msg = nil)
        assert(expected == actual, msg || "#{actual} is expected to be #{expected}", 2)
      end

      def assert_not_equal(expected, actual, msg = nil)
        assert(expected != actual, msg || "#{actual} is expected not to be #{expected}", 2)
      end

      def assert_nil(object, msg=nil)
        assert(object.nil?, msg || "#{object} is expected to be nil", 2)
      end

      def assert_not_nil(object, msg=nil)
        assert(!object.nil?, msg || "#{object} is expected not to be nil.", 2)
      end

      private
      def assert(boolean, msg = nil, level = 2)
        if boolean
          logger.wj_debug("Assertion passed at #{caller(level).first}")
        else
          logger.wj_error("Assertion failed at #{caller(level).first}")
          raise WebJourney::AssertionFailedError.new("Assertion failed.")
        end
      end
    end
  end
end

ActiveRecord::Base.send     :include, WebJourney::Assertion::Methods
ActionController::Base.send :include, WebJourney::Assertion::Methods
