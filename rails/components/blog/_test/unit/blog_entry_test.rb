require File.dirname(__FILE__) + '/../test_helper'

class BlogSettingTest < ActiveSupport::TestCase

  def test_by_blog_setting_id_and_post_date
    5.times do |i|
      entry = Blog::BlogEntry.new
      entry.blog_setting_id = "yssk22"
      entry.created_by = "yssk22"
      entry.updated_by = "yssk22"
      entry.title      = "title_#{i}"
      entry.content    = "content ... #{i}"
      entry.post_date  = Time.today
      assert entry.save
    end
    assert_equal 5, Blog::BlogEntry.by_blog_setting_id_all(:by_post_date, :startkey => ["yssk22"], :endkey => ["yssk22", "\u0000"])[:rows].length

    10.times do |i|
      entry = Blog::BlogEntry.new
      entry.blog_setting_id = "administrator"
      entry.created_by = "administrator"
      entry.updated_by = "administrator"
      entry.title      = "title_#{i}"
      entry.content    = "content ... #{i}"
      entry.post_date  = Time.today
      assert entry.save
    end
    assert_equal 10, Blog::BlogEntry.by_blog_setting_id_all(:by_post_date, :startkey => ["administrator"], :endkey => ["administrator", "\u0000"])[:rows].length
  end
end
