require File.dirname(__FILE__) + '/../test_helper'

class BlogSettingTest < ActiveSupport::TestCase

  def test_by_login_name
    a = Blog::BlogSetting.new
    a.id    = "yssk22"
    a.title = "test_yssk22"
    assert_not_nil a.save

    b = Blog::BlogSetting.new
    b.id    = "administrator"
    b.title = "test_administrator"
    assert_not_nil b.save

    @settings = Blog::BlogSetting.by_login_name_all(:all)[:rows]
    assert_equal 2, @settings.length

    @settings = Blog::BlogSetting.by_login_name_all(:all, :key => "yssk22")[:rows]
    assert_equal 1, @settings.length
  end

  def test_allow_view
    blog = Blog::BlogSetting.default
    blog.id    = "yssk22"
    blog.title = "test_yssk22"
    assert_not_nil blog.save
    assert_true blog.allow_view?(wj_users(:anonymous))
    assert_true blog.allow_view?(wj_users(:administrator))
    assert_true blog.allow_view?(wj_users(:ma))

    blog.allow_view(:all => false, :tags => ["private"])
    assert_false blog.allow_view?(wj_users(:anonymous))
    assert_false blog.allow_view?(wj_users(:administrator))
    assert_true blog.allow_view?(wj_users(:ma))
  end
end
