# The extension for functional tests
class Test::Unit::TestCase
  def login(user, &block)
    if block
      begin
        @controller.set_current_user(user)
        yield
      ensure
        logout
      end
    else
      @controller.set_current_user(user)
    end
  end

  def logout
    @controller.set_current_user(nil)
  end
end
