require File.join(File.dirname(__FILE__), '../test_helper')

class WjPageTest < ActiveSupport::TestCase
  def setup
  end

  def teardown
  end

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
end
