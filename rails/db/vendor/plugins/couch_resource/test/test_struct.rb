require 'test/unit'

require File.join(File.dirname(__FILE__), "../lib/couch_resource/struct")

class StringTest
  include CouchResource::Struct
  string :member
  string :nillable_member, :allow_nil => true
end

class NumberTest
  include CouchResource::Struct
  number :member
end

class BooleanTest
  include CouchResource::Struct
  boolean :member
end

class ArrayTest
  include CouchResource::Struct
  array :member
end

class ObjectTest
  include CouchResource::Struct
  object :member
end

class CollectionTest
  include CouchResource::Struct
  class NestedClass
    include CouchResource::Struct
    string :member
  end
  collection :member, :each => NestedClass
end

class NestedObjectTest
  include CouchResource::Struct
  class NestedClass
    include CouchResource::Struct
    object :member
  end
  object :nest, :is_a => NestedClass
end

class DateTimeTest
  include CouchResource::Struct
  datetime :member
end


class TestStruct < Test::Unit::TestCase
  def test_string
    obj = StringTest.new
    # test attribute (with implicit type conversion)
    obj.member = "hogehoge"
    assert_equal "hogehoge", obj.member
    obj.member = 1
    assert_equal "1", obj.member
    obj.member = true
    assert_equal "true", obj.member
    obj.member = [1,2,3]
    assert_equal "123", obj.member
    obj.member = { :hoge => :fuga }
    assert_equal "hogefuga", obj.member

    # test to_hash
    obj.member = "hogehoge"
    assert_equal({ "class" => "StringTest",
                   "member" => "hogehoge",
                   "nillable_member" => nil},
                 obj.to_hash)

    # test from_hash
    assert_equal obj.member, StringTest.from_hash(obj.to_hash).member

    # test allow_nil
    obj.nillable_member = "a"
    assert_equal "a", obj.nillable_member
    obj.nillable_member = nil
    assert_nil obj.nillable_member
    obj.nillable_member = false
    assert_nil obj.nillable_member

  end

  def test_number
    obj = NumberTest.new
    # test attribute (with implicit type conversion)
    obj.member = 10
    assert_equal 10, obj.member
    obj.member = 10.1
    assert_equal 10.1, obj.member
    obj.member = "hogehoge"
    assert_equal 0, obj.member
    obj.member = "111"
    assert_equal 111, obj.member
    obj.member = true
    assert_equal 0, obj.member
    obj.member = [1,2,3]
    assert_equal 123, obj.member    # because [1,2,3] (to_s) =>  "123" (to_i) =>
    obj.member = { :hoge => :fuga }
    assert_equal 0, obj.member


    # test to_hash
    obj.member = 10
    assert_equal({"class" => "NumberTest", "member" => 10},
                 obj.to_hash)

    # test from_hash
    assert_equal obj.member, NumberTest.from_hash(obj.to_hash).member
  end

  def test_boolean
    obj = BooleanTest.new
    # test attribute (with implicit type conversion)
    obj.member = true
    assert obj.member
    assert obj.member?
    obj.member = 10
    assert_equal true, obj.member
    obj.member = 10.1
    assert_equal true, obj.member
    obj.member = "hogehoge"
    assert_equal true, obj.member
    obj.member = "111"
    assert_equal true, obj.member
    obj.member = [1,2,3]
    assert_equal true, obj.member    # because [1,2,3] (to_s) =>  "123" (to_i) =>
    obj.member = { :hoge => :fuga }
    assert_equal true, obj.member
    obj.member = false
    assert !obj.member
    assert !obj.member?

    # test to_hash
    obj.member = true
    assert_equal({"class" => "BooleanTest", "member" => true},
                 obj.to_hash)
    # test from_hash
    assert_equal obj.member, BooleanTest.from_hash(obj.to_hash).member

    obj.member = false
    assert_equal({"class" => "BooleanTest", "member" => false},
                 obj.to_hash)
    # test from_hash
    assert_equal obj.member, BooleanTest.from_hash(obj.to_hash).member



  end

  def test_array
    obj = ArrayTest.new
    # test attribute (with implicit type conversion)
    obj.member = []
    assert_equal [], obj.member
    obj.member = 10
    assert_equal [10], obj.member
    obj.member = 10.1
    assert_equal [10.1], obj.member
    obj.member = "hogehoge"
    assert_equal ["hogehoge"], obj.member
    obj.member = [1,2,3]
    assert_equal [1,2,3], obj.member    # because [1,2,3] (to_s) =>  "123" (to_i) =>
    obj.member = { :hoge => :fuga }
    assert_equal [[:hoge , :fuga]] , obj.member

    # test to_hash
    obj.member = []
    assert_equal({"class" => "ArrayTest", "member" => []},
                 obj.to_hash)
    assert_equal obj.member, ArrayTest.from_hash(obj.to_hash).member

    # test from_hash
    obj.member = "hoge"
    assert_equal ["hoge"], obj.member
    assert_equal({"class" => "ArrayTest", "member" => ["hoge"]},
                 obj.to_hash)
    assert_equal obj.member, ArrayTest.from_hash(obj.to_hash).member
  end

  def test_collection
    obj = CollectionTest.new
    # test attribute (with implicit type conversion)
    obj.member = []
    assert_equal [], obj.member
    obj.member = 10
    assert_equal [], obj.member
    obj.member = 10.1
    assert_equal [], obj.member
    obj.member = "hogehoge"
    assert_equal [], obj.member
    obj.member = [1,2,3]
    assert_equal [], obj.member    # because [1,2,3] (to_s) =>  "123" (to_i) =>
    obj.member = { :hoge => :fuga }
    assert_equal [] , obj.member

    obj.member = []
    obj.member << CollectionTest::NestedClass.from_hash({:member => "hoge"})

    assert_equal "hoge", obj.member.first.member

    #obj.member = []
    #obj.member << {:member => "hoge"}

    # test to_hash
    obj.member = []
    assert_equal({"class" => "CollectionTest", "member" => []},
                 obj.to_hash)
    assert_equal obj.member, CollectionTest.from_hash(obj.to_hash).member

    # test from_hash
    obj.member = "hoge"
    assert_equal [], obj.member
    assert_equal({"class" => "CollectionTest", "member" => []},
                 obj.to_hash)
    assert_equal obj.member, CollectionTest.from_hash(obj.to_hash).member
  end

  def test_object
    obj = ObjectTest.new
    # test attribute (with implicit type conversion)
    obj.member = []
    assert_nil obj.member
    obj.member = 10
    assert_nil obj.member
    obj.member = 10.1
    assert_nil obj.member
    obj.member = "hogehoge"
    assert_nil obj.member
    obj.member = [1,2,3]
    assert_nil obj.member
    obj.member = { "hoge" => :fuga }
    assert_equal({ "hoge" => :fuga }, obj.member)

    # test to_hash & from_hash
    obj.member = nil
    assert_nil obj.member
    assert_equal({ "class" => "ObjectTest",
                   "member" => nil
                 }, obj.to_hash)
    assert_equal obj.member, ObjectTest.from_hash(obj.to_hash).member
    obj.member = {
      :hoge => :fuga,
      :foo  => :bar
    }
    assert_equal :fuga, obj.member[:hoge]
    assert_equal :bar,  obj.member[:foo]
    assert_equal({ "class" => "ObjectTest",
                   "member" => {
                     "hoge" => :fuga,
                     "foo"  => :bar
                   }},
                 obj.to_hash)
    assert_equal obj.member, ObjectTest.from_hash(obj.to_hash).member
  end

  def test_nested_object
    obj = NestedObjectTest.new
    assert_nil obj.nest
    assert_equal({ "class" => "NestedObjectTest",
                   "nest" => nil
                 }, obj.to_hash)
    obj.nest = NestedObjectTest::NestedClass.new
    assert_not_nil obj.nest
    assert_equal({ "class" => "NestedObjectTest",
                   "nest" => {
                     "class" => "NestedObjectTest::NestedClass",
                     "member" => nil
                   }
                 }, obj.to_hash)
    assert_equal obj.nest.member, NestedObjectTest.from_hash(obj.to_hash).nest.member

    obj.nest.member = {
      :hoge => :fuga,
      :foo  => :bar
    }
    assert_equal :fuga, obj.nest.member[:hoge]
    assert_equal :bar,  obj.nest.member[:foo]
    assert_equal({"class" => "NestedObjectTest",
                   "nest" => {
                     "class" => "NestedObjectTest::NestedClass",
                     "member" => {
                       "hoge" => :fuga,
                       "foo"  => :bar
                     }
                   }
                 },
                 obj.to_hash)
    assert_equal obj.nest.member[:hoge], NestedObjectTest.from_hash(obj.to_hash).nest.member[:hoge]
    assert_equal obj.nest.member[:foo],  NestedObjectTest.from_hash(obj.to_hash).nest.member[:foo]

  end

  def test_datetime
    obj = DateTimeTest.new
    obj.member = Time.now
    assert_not_nil obj.member
    obj.member = Date.today
    assert_not_nil obj.member
    obj.member = DateTime.now
    assert_not_nil obj.member
    # test attribute (with implicit type conversion)
    obj.member = DateTime.now.to_s
    assert_not_nil obj.member
    obj.member = "hogehoge"
    assert_nil obj.member
    obj.member = 1
    assert_nil obj.member
    obj.member = true
    assert_nil obj.member
    obj.member = [1,2,3,4,5,6]
    assert_nil obj.member
    obj.member = { :hoge => :fuga }
    assert_nil obj.member

    # test to_hash
    d = DateTime.now
    obj.member = d
    assert_equal({ "class" => "DateTimeTest",
                   "member" => d},
                 obj.to_hash)

    # test from_hash
    assert_equal obj.member, DateTimeTest.from_hash(obj.to_hash).member
  end
end
