require File.join(File.dirname(__FILE__), '../test_helper')

class WjPageTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

  def test_top
    assert_not_nil WjPage.top
  end

  def test_create_new
    page = WjPage.create_new("administrator")
    assert_not_nil page
    assert_false page.new?
    assert_equal "administrator", page.owner_login_name
  end

  def test_my_page_for
    # ma has no page.
    page =  WjPage.my_page_for("ma")
    assert_nil page

    # ma has no page and create new one.
    page = WjPage.my_page_for("ma", true)
    assert_not_nil page
    assert_false page.new?
    assert_equal 1, page.widget_instances(:center).length
    display = page.widget_instances(:center).first
    assert_not_nil display.id
    assert_equal "ma's home", display.title

    # next time, page and page2 is the same
    page2 = WjPage.my_page_for("ma", true)
    assert_equal page.id, page2.id
  end

  def test_allow_to_create?
    assert_true WjPage.allow_to_create?("administrator")
    assert_true WjPage.allow_to_create?("yssk22")
    assert_false WjPage.allow_to_create?("prepared_test_user")
    assert_false WjPage.allow_to_create?("anonymous")
  end

  def test_owner
    assert_equal WjUser::BuiltIn::Administrator.me, WjPage.top.owner
  end

  def test_shown_to?
    page = WjPage.find("test_page2")
    assert_false page.shown_to?(wj_users(:anonymous))
    assert_false page.shown_to?(wj_users(:taro))
    assert_true page.shown_to?(wj_users(:ma))
    assert_true page.shown_to?(wj_users(:yssk22))
  end

  def test_updated_by?
    page = WjPage.find("test_page1")
    assert_false page.updated_by?(wj_users(:anonymous))
    assert_false page.updated_by?(wj_users(:taro))
    assert_true page.updated_by?(wj_users(:ma))
    assert_true page.updated_by?(wj_users(:yssk22))
  end

  def test_deleted_by?
    page = WjPage.top
    assert_false page.deleted_by?(wj_users(:anonymous))
    assert_false page.deleted_by?(wj_users(:yssk22))
    assert_true  page.deleted_by?(wj_users(:administrator))
  end

  def test_left_container_width
    page = WjPage.find("test_page1")
    assert_equal "200px", page.left_container_width
  end

  def test_right_container_width
    page = WjPage.find("test_page1")
    assert_equal "200px", page.right_container_width
  end

  def test_widget_instances
    page = WjPage.top
    instances = page.widget_instances
    assert_not_nil instances
    assert_equal 5, instances.keys.length
    assert_equal 0, instances[:top].length
    assert_equal 2, instances[:center].length
    assert_equal 0, instances[:left].length
    assert_equal 0, instances[:right].length
    assert_equal 0, instances[:bottom].length

    instances = page.widget_instances(:top)
    assert_equal 0, instances.length
    instances = page.widget_instances(:center)
    assert_equal 2, instances.length
  end

  def test_get_old_widget_instances
    page = WjPage.top
    instances = page.widget_instances
    assert_equal 2, instances[:center].length

    page.compose_widget_instance_layout(:top    => [],
                                        :left   => [],
                                        :center => [],
                                        :right  => [],
                                        :bottom => [])
    page.save
    instances = page.widget_instances
    assert_equal 0, instances[:center].length

    old = page.get_old_widget_instances
    assert_equal 2, old.length
  end



=begin
  def test_my_page_for
    page =  WjPage.my_page_for("yssk22")
    assert_not_nil page
    assert_equal "test_page1", page._id
  end

  def test_new
    page = WjPage.new(:owner_login_name => WjUser::BuiltIn::Administrator.me.login_name)
    [:width, :lwidth, :rwidth].each do |attr|
      assert_equal WjConfig["design_#{attr}"],      page[attr]
      assert_equal WjConfig["design_#{attr}_unit"], page["#{attr}_unit"]
    end
    [:title, :robots_index, :robots_follow, :description, :copyright].each do |attr|
      assert_equal WjConfig["site_#{attr}"],        page[attr]
    end
    assert_equal WjConfig[:site_keywords].split(","), page["keywords"]
    assert_true page.save
    assert_true page.destroy
  end

  def test_new_with_attributes
    page = WjPage.new(:title => "original title",
                      :owner_login_name => WjUser::BuiltIn::Administrator.me.login_name)
    assert_equal "original title", page.title
    assert_true page.save
    assert_true page.destroy
  end

  def test_top
    page = WjPage.top
    assert_equal "Top Page", page.title
    assert_equal "top", page.id
  end

  def test_owner
    page = WjPage.top
    assert_equal WjUser::BuiltIn::Administrator.me.login_name, page.owner_login_name
    assert_equal WjUser::BuiltIn::Administrator.me, page.owner
  end

  def test_relationship_keys
    page = WjPage.top
    assert_true      page.relationship_keys.show.all
    assert_equal [], page.relationship_keys.show.tags
    assert_false     page.relationship_keys.edit.all
    assert_equal [], page.relationship_keys.edit.tags
  end

  def test_permit_relationship_of
    page = WjPage.find("test_page1")
    assert_true      page.relationship_keys.show.all
    assert_equal [], page.relationship_keys.show.tags
    assert_false                         page.relationship_keys.edit.all
    assert_equal ["private", "friends"], page.relationship_keys.edit.tags

    assert_true page.permit_relationship_of?(wj_users(:yssk22), :show)
    assert_true page.permit_relationship_of?(wj_users(:ma),     :show)
    assert_true page.permit_relationship_of?(wj_users(:joe),    :show)
    assert_true page.permit_relationship_of?(wj_users(:elly),   :show)
    assert_true page.permit_relationship_of?(wj_users(:taro),   :show)
    assert_true page.permit_relationship_of?(wj_users(:hanako), :show)

    assert_true  page.permit_relationship_of?(wj_users(:yssk22), :edit)
    assert_true  page.permit_relationship_of?(wj_users(:ma),     :edit)
    assert_true  page.permit_relationship_of?(wj_users(:joe),    :edit)
    assert_false page.permit_relationship_of?(wj_users(:elly),   :edit)
    assert_false page.permit_relationship_of?(wj_users(:taro),   :edit)
    assert_false page.permit_relationship_of?(wj_users(:hanako), :edit)
  end

  def test_compose_widget_instance_layout
    page = WjPage.top
    layout = {
      :top => [{ :component => "test", :widget => "widget1" },
               { :component => "test", :widget => "widget1" },
               { :component => "test", :widget => "widget1" },
               { :component => "test", :widget => "widget1" }]
    }
    page.compose_widget_instance_layout(layout)
    assert_equal 4, page.widgets[:top].length
    page.widgets[:top].each do |pointer|
      assert_not_nil pointer[:instance_id]
    end
    new_layout = {
      :top => page.widgets[:top]
    }
    new_layout[:top] << { :component => "test", :widget => "widget2" }

    page.compose_widget_instance_layout(new_layout)
    assert_equal 5, page.widgets[:top].length
    page.widgets[:top].each do |pointer|
      assert_not_nil pointer[:instance_id]
    end
  end

  def test_get_widget_instances
    page = WjPage.top
    layout = {
      :top => [{ :component => "test", :widget => "widget1" },
               { :component => "test", :widget => "widget1" }]
    }
    page.compose_widget_instance_layout(layout)
    assert_true page.save
    rows = page.get_current_widget_instances()
    assert_equal 2, rows.length


    newlayout = {
      :top => [{ :component => "test", :widget => "widget1" },
               { :component => "test", :widget => "widget1" },
               { :component => "test", :widget => "widget2" }]
    }
    page.compose_widget_instance_layout(newlayout)
    assert_true page.save
    rows = page.get_current_widget_instances()
    assert_equal 3, rows.length

    rows = page.get_old_widget_instances()
    assert_equal 2, rows.length

    rows = page.get_all_widget_instances()
    assert_equal 5, rows.length
  end

  def test_clean_up_old_widget_instances
    test_get_widget_instances
    page = WjPage.top
    page.clean_up_old_widget_instances
    rows = page.get_all_widget_instances()
    assert_equal 3, rows.length
    rows = page.get_old_widget_instances()
    assert_equal 0, rows.length
  end
=end
end
