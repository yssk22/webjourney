require File.dirname(__FILE__) + '/../../../../test/test_helper'

class ComponentTest < Test::Unit::TestCase

  def setup
    @archive_test = WebJourney::Component::Package.new("archive_test")
    @deploy_test = WebJourney::Component::Package.new("deploy_test")
  end

  def test_copy_to_and_cleanup_archived
    assert_ready_to_archive
    @archive_test.copy_to_archived

    assert_true File.exist?(@archive_test.archived_components_directory)
    assert_true File.exist?(@archive_test.archived_static_files_directory)

    @archive_test.cleanup_archived
    assert_ready_to_archive
  end

  def test_copy_to_and_cleanup_deployed
    assert_ready_to_deploy
    @deploy_test.copy_to_deployed

    assert_true File.exist?(@deploy_test.deployed_components_directory)
    assert_true File.exist?(@deploy_test.deployed_static_files_directory)

    @deploy_test.cleanup_deployed
    assert_ready_to_deploy
  end

  def test_register_and_unregister
    assert_ready_to_archive
    @archive_test.register
    rec = WjComponent.find_by_programatic_name("archive_test")
    assert_not_nil rec
    assert_equal "Archive Test", rec.display_name
    assert_equal "MIT", rec.license
    assert_equal "http://www.example.com/archive_test", rec.url
    assert_equal "yssk22", rec.author
    assert_equal "description of archive test", rec.description
    assert_equal 2, rec.wj_component_pages.length
    assert_equal "test",  rec.wj_component_pages.first.controller_name
    assert_equal "Test",  rec.wj_component_pages.first.display_name
    assert_equal 1,       rec.wj_widgets.length
    assert_equal "widget", rec.wj_widgets.first.controller_name
    assert_equal "Widget", rec.wj_widgets.first.display_name

    page_ids   = rec.wj_component_pages.map(&:id)
    widget_ids = rec.wj_widgets.map(&:id)
    @archive_test.unregister

    assert_nil WjComponent.find_by_programatic_name("archive_test")
    assert_raise(ActiveRecord::RecordNotFound) { WjComponentPage.find(page_ids) }
    assert_raise(ActiveRecord::RecordNotFound) { WjWidget.find(widget_ids) }
  end

  def test_definitions_from_archived
    assert_ready_to_deploy
    definitions = @deploy_test.definitions_from_archived
    assert_equal "Deploy Test", definitions[:wj_component]["display_name"]
    assert_not_nil definitions[:wj_component_pages].first["page"]
    assert_not_nil definitions[:wj_widgets].last["widget"]
  end

  def test_definitions_from_deployed
    assert_ready_to_archive
    definitions = @archive_test.definitions_from_deployed
    assert_equal "Archive Test", definitions[:wj_component]["display_name"]
    assert_not_nil definitions[:wj_component_pages].first["test"]
    assert_not_nil definitions[:wj_component_pages].last["page"]
    assert_not_nil definitions[:wj_widgets].last["widget"]
  end


  def test_migrations
    test_register_and_unregister
    @archive_test.register

    assert_equal 0, @archive_test.current_version
    @archive_test.migrate
    assert_equal 2, @archive_test.current_version

    @archive_test.migrate 0
    assert_equal 0, @archive_test.current_version

    @archive_test.unregister
  end

  def test_latest_version
    assert_ready_to_archive
    assert_equal 2, @archive_test.latest_version
  end

  def test_current_version
    test_register_and_unregister
    @archive_test.register
    assert_equal 0, @archive_test.current_version
    @archive_test.unregister
  end


  private
  def assert_ready_to_archive
    assert_false File.exist?(@archive_test.archived_components_directory)
    assert_false File.exist?(@archive_test.archived_static_files_directory)
    assert_equal [], @archive_test.archived_po_files

    assert_true File.exist?(@archive_test.deployed_components_directory)
    assert_true File.exist?(@archive_test.deployed_static_files_directory)
    @archive_test.deployed_po_files.each do |f|
      assert_true File.exist?(f)
    end
  end

  def assert_ready_to_deploy
    assert_true  File.exist?(@deploy_test.archived_components_directory)
    assert_true  File.exist?(@deploy_test.archived_static_files_directory)
    assert_false File.exist?(@deploy_test.deployed_components_directory)
    assert_false File.exist?(@deploy_test.deployed_static_files_directory)
  end
end
