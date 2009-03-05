require 'test/unit'
require File.join(File.dirname(__FILE__), "../lib/couch_resource")

TEST_DB_PATH  = "couch_resource_base_test"

CouchResource::Base.logger = Logger.new("/dev/null")
CouchResource::Base.check_design_revision_every_time = true
# CouchResource::Base.logger = Logger.new(STDOUT)

class SimpleDocument < CouchResource::Base
  self.database = "http://localhost:5984/#{TEST_DB_PATH}"
  string :title
  string :content

  view :simple_document, {
    :all_by_id => {
      :map => "function(doc){ emit(doc._id, doc); }"
    },
    :all_by_title => {
      :map => "function(doc){ emit(doc.title, doc); }"
    }
  }
end

class StrictDocument < CouchResource::Base
  self.database = "http://localhost:5984/#{TEST_DB_PATH}"
  string :title, :validates => [
    [:length_of, {:maximum => 20}],
    [:length_of, {:on => :create, :minimum => 5}],
    [:length_of, {:on => :update, :minimum => 10}]
  ]
end

class MagicAttributesTest < CouchResource::Base
  self.database = "http://localhost:5984/#{TEST_DB_PATH}"
  datetime :created_at
  datetime :created_on
  datetime :updated_at
  datetime :updated_on
end

class TestBase < Test::Unit::TestCase
  def setup
    res = SimpleDocument.connection.put(SimpleDocument.database.path)
    unless res[:ok]
      puts "Failed to create test database. Check couchdb server running."
    end
  end

  def teardown
    res = SimpleDocument.connection.delete(SimpleDocument.database.path)
    unless res[:ok]
      puts "Failed to drop test database. Delete manually before you test next time."
    end
  end


  def test_new?
    doc = SimpleDocument.new(:title => "title", :content => "content")
    assert doc.new?
    doc = SimpleDocument.new(:_id => "simple_document", :title => "title", :content => "content")
    assert doc.new?
    doc = SimpleDocument.new(:_id => "simple_document", :_rev => "1234",
                             :title => "title", :content => "content")
    assert !doc.new?
  end

  def test_create_without_id
    doc = SimpleDocument.new(:title => "title", :content => "content")
    assert doc.save
    assert_not_nil doc.id
    assert_not_nil doc.rev
  end

  def test_create_with_id
    doc = SimpleDocument.new(:_id => "simple_document", :title => "title", :content => "content")
    assert doc.save
    assert_equal "simple_document", doc.id
    assert_not_nil doc.rev
  end

  def test_create_with_validation_failed
    doc = StrictDocument.new(:_id => "simple_document", :title => "123", :content => "content")
    assert !doc.save
    assert_raise(CouchResource::ResourceNotFound) { StrictDocument.find("simple_document")}
    doc.title = "1" * 5
    assert doc.save
    doc = StrictDocument.find("simple_document")
    assert_not_nil doc
    assert !doc.save
    doc.title = "1" * 11
    assert doc.save
    doc.title = "1" * 25
    assert !doc.save
  end

  def test_update
    doc1 = SimpleDocument.new(:title => "title", :content => "content")
    assert doc1.save
    old_rev = doc1.rev
    assert_not_nil doc1.id
    assert_not_nil doc1.rev
    doc1.content = "updated"
    doc1.save
    doc2 = SimpleDocument.find(doc1.id)
    assert_equal "updated", doc2.content
    assert_not_equal old_rev, doc2.rev
  end

  def test_destroy
    doc1 = SimpleDocument.new(:title => "title", :content => "content")
    doc1.save
    old_id  = doc1.id
    old_rev = doc1.rev
    assert_not_nil doc1.id
    assert_not_nil doc1.rev
    doc1.destroy
    assert_not_nil doc1.id
    assert_nil doc1.rev
    assert_raise(CouchResource::ResourceNotFound) { SimpleDocument.find(old_id) }
    doc1.save
    doc1 = SimpleDocument.find(old_id)
    assert_equal old_id, doc1.id
    assert_not_equal old_rev, doc1.rev
  end

  def test_revs
    doc1 = SimpleDocument.new(:title => "title", :content => "content")
    revs = []
    5.times do
      assert doc1.save
      revs << doc1.rev
    end
    revs.reverse!
    retrieved = doc1.revs
    assert_equal 5, retrieved.length
    assert_equal revs, retrieved
    retrieved = doc1.revs(true)
    retrieved.each_with_index do |revinfo, i|
      assert_not_nil revinfo
      assert_equal revs[i], revinfo[:rev]
      assert_equal "available", revinfo[:status]
    end
  end

  def test_find_from_ids()
    doc1 = SimpleDocument.new(:title => "title", :content => "content")
    doc1.save
    # find an document
    doc2 = SimpleDocument.find(doc1.id)
    assert_equal "title", doc2.title
    assert_equal "content",  doc2.content
    assert_equal doc1.rev, doc2.rev
    assert_equal doc1.id,  doc2.id
    # find multiple documents
    docs = SimpleDocument.find(doc1.id, doc2.id)
    docs.each do |doc|
      assert_equal "title",  doc.title
      assert_equal "content",  doc2.content
      assert_equal doc1.rev, doc.rev
      assert_equal doc1.id,  doc.id
    end
    # find with :rev option
    doc2 = SimpleDocument.find(doc1.id, :rev => doc1.rev)
    doc2 = SimpleDocument.find(doc1.id)
    assert_equal "title", doc2.title
    assert_equal "content",  doc2.content
    assert_equal doc1.rev, doc2.rev
    assert_equal doc1.id,  doc2.id
  end

  def test_find_first
    register_simple_documents()
    # without any options
    doc = SimpleDocument.find_simple_document_all_by_title_first
    assert_not_nil doc
    assert_equal "title_0", doc.title
    assert_equal "content_0", doc.content

    # with descending option (same as SimpleDocument.last without descending option)
    doc = SimpleDocument.find_simple_document_all_by_title_first(:descending => true)
    assert_not_nil doc
    assert_equal "title_9", doc.title
    assert_equal "content_9", doc.content

    # with offset option
    doc = SimpleDocument.find_simple_document_all_by_title_first(:skip => 1)
    assert_not_nil doc
    assert_equal "title_1", doc.title
    assert_equal "content_1", doc.content

    # with key options
    doc = SimpleDocument.find_simple_document_all_by_title_first(:key => "title_2")
    assert_not_nil doc
    assert_equal "title_2", doc.title
    assert_equal "content_2", doc.content
  end

  def test_find_last
    register_simple_documents()
    # without any options
    doc = SimpleDocument.find_simple_document_all_by_title_last
    assert_not_nil doc
    assert_equal "title_9", doc.title
    assert_equal "content_9", doc.content

    # with descending option (same as SimpleDocument.last without descending option)
    doc = SimpleDocument.find_simple_document_all_by_title_last(:descending => true)
    assert_not_nil doc
    assert_equal "title_0", doc.title
    assert_equal "content_0", doc.content

    # with key option
    doc = SimpleDocument.find_simple_document_all_by_title_last(:key => "title_2")
    assert_not_nil doc
    assert_equal "title_2", doc.title
    assert_equal "content_2", doc.content
  end

  def test_find_all
    register_simple_documents()
    # without any options
    docs = SimpleDocument.find_simple_document_all_by_title
    assert_not_nil docs
    (0..9).each do |i|
      doc = docs[:rows][i]
      assert_not_nil doc
      assert_equal "title_#{i}", doc.title
      assert_equal "content_#{i}", doc.content
    end

    # with descending option
    docs = SimpleDocument.find_simple_document_all_by_title(:descending => true)
    (0..9).each do |i|
      doc = docs[:rows][i]
      assert_equal "title_#{9-i}", doc.title
      assert_equal "content_#{9-i}", doc.content
    end

    # with key option
    docs = SimpleDocument.find_simple_document_all_by_title(:key => "title_1")
    assert_equal 1, docs[:rows].length
    assert_equal "title_1", docs[:rows].first.title
    assert_equal "content_1", docs[:rows].first.content
    # with key option (no matching)
    docs = SimpleDocument.find_simple_document_all_by_title(:key => "1")
    assert_equal 0, docs[:rows].length

    # with startkey option
    docs = SimpleDocument.find_simple_document_all_by_title(:startkey => "title_5")
    assert_equal 5, docs[:rows].length
    (5..9).each do |i|
      doc = docs[:rows][i-5]
      assert_not_nil doc
      assert_equal "title_#{i}", doc.title
      assert_equal "content_#{i}", doc.content
    end

    # with endkey option
    docs = SimpleDocument.find_simple_document_all_by_title(:endkey => "title_4")
    assert_equal 5, docs[:rows].length
    (0..4).each do |i|
      doc = docs[:rows][i]
      assert_not_nil doc
      assert_equal "title_#{i}", doc.title
      assert_equal "content_#{i}", doc.content
    end

    # with startkey and endkey option
    docs = SimpleDocument.find_simple_document_all_by_title(:startkey => "title_3", :endkey => "title_6")
    assert_equal 4, docs[:rows].length
    (3..6).each do |i|
      doc = docs[:rows][i-3]
      assert_not_nil doc
      assert_equal "title_#{i}", doc.title
      assert_equal "content_#{i}", doc.content
    end
  end


  def test_paginate
    register_simple_documents()

    # retrieve all documentes
    docs = SimpleDocument.find_simple_document_all_by_title(:count => 10)
    assert_nil  docs[:previous]
    assert_nil  docs[:next]
    assert_equal "title_0", docs[:rows].first.title
    assert_equal "title_9", docs[:rows].last.title

    # retrive documents per 4 docs.
    # 0..3
    docs = SimpleDocument.find_simple_document_all_by_title(:count => 4)
    assert_equal -1, docs[:previous][:expected_offset]
    assert docs[:next][:expected_offset] > 0
    assert_equal "title_0", docs[:rows].first.title
    assert_equal "title_3", docs[:rows].last.title

    # next
    # 4..7
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:next])
    assert docs[:previous][:expected_offset] > 0
    assert docs[:next][:expected_offset] > 0
    assert_equal "title_4", docs[:rows].first.title
    assert_equal "title_7", docs[:rows].last.title

    # next (it remains only 2 docs);
    # 8..9
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:next])
    assert docs[:previous][:expected_offset] > 0
    assert_equal -1, docs[:next][:expected_offset]
    assert_equal "title_8", docs[:rows].first.title
    assert_equal "title_9", docs[:rows].last.title

    # previous (should return 4 docs before title_8)
    # 4..7
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:previous])
    assert docs[:previous][:expected_offset] > 0
    assert docs[:next][:expected_offset] > 0
    assert_equal "title_4", docs[:rows].first.title
    assert_equal "title_7", docs[:rows].last.title

    # previous (should return 4 docs before title_4)
    # 0..3
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:previous])
    assert docs[:previous][:expected_offset] > 0
    assert docs[:next][:expected_offset] > 0
    assert_equal "title_0", docs[:rows].first.title
    assert_equal "title_3", docs[:rows].last.title

    # previous over reached
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:previous])
    assert_equal -1, docs[:previous][:expected_offset]
    assert_nil docs[:next][:expected_offset]
    assert_equal 0, docs[:rows].length

    # more complex case
    # fetch more than half documents at first access and with descending option
    # retrieve 9 documentes (from 9 to 1)
    docs = SimpleDocument.find_simple_document_all_by_title(:descending => true, :count => 9)
    assert_equal -1, docs[:previous][:expected_offset]
    assert docs[:next][:expected_offset] > 0
    assert_equal "title_9", docs[:rows].first.title
    assert_equal "title_1", docs[:rows].last.title

    # next
    # only 0
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:next])
    assert docs[:previous][:expected_offset] > 0
    assert_equal -1, docs[:next][:expected_offset]
    assert_equal "title_0", docs[:rows].first.title

    # previous
    # 9..1
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:previous])
    assert docs[:previous][:expected_offset] > 0
    assert docs[:next][:expected_offset] > 0
    assert_equal "title_9", docs[:rows].first.title
    assert_equal "title_1", docs[:rows].last.title

    # previous over reached
    docs = SimpleDocument.find_simple_document_all_by_title(docs[:previous])
    assert_equal -1, docs[:previous][:expected_offset]
    assert_nil docs[:next][:expected_offset]
    assert_equal 0, docs[:rows].length
  end

  private
  def register_simple_documents
    0.upto(9) do |i|
      doc = SimpleDocument.new(:title => "title_#{i}", :content => "content_#{i}")
      doc.save
    end
  end

  def test_magic_attributes
    obj = MagicAttributesTest
    obj.save
    assert_not_nil obj.created_at
    assert_not_nil obj.created_on
    assert_not_nil obj.updated_at
    assert_not_nil obj.updated_on
  end
end
