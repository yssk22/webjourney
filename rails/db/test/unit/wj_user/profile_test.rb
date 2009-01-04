require File.join(File.dirname(__FILE__), '../../test_helper')

class WjUser::ProfileTest < ActiveSupport::TestCase

  def test_relationships
    @yssk22 = wj_users(:yssk22)
    assert_equal 3, @yssk22.profile.relationships.keys.length
    assert_true @yssk22.profile.relationships.values.first.is_a?(Array)
  end

  def test_related_to?
    @yssk22 = wj_users(:yssk22)
    # without tag
    assert_true @yssk22.related_to?(wj_users(:ma))
    assert_false @yssk22.related_to?(wj_users(:elly))
    # with tag
    assert_true @yssk22.related_to?(wj_users(:ma), "private")
    assert_false @yssk22.related_to?(wj_users(:ma), "friends")
  end

  def test_remove_relationship
    @yssk22 = wj_users(:yssk22)
    assert_true @yssk22.related_to?(wj_users(:ma))
    @yssk22.profile.remove_relationship(wj_users(:ma))
    assert_false @yssk22.related_to?(wj_users(:ma))
    @yssk22.profile.save
    @yssk22.profile(true)
    assert_false @yssk22.related_to?(wj_users(:ma))
  end

end
