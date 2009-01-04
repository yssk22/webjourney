require 'test/unit'

require File.join(File.dirname(__FILE__), "../lib/couch_resource/validations")

class ValidatesEachTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :first_name, :validates => [
    [:each , {
       :proc => Proc.new do |record, attr, value|
         record.errors.add attr, "starts with z." if value[0] == ?z
       end
     }]
  ]
end

class ValidatesConfirmationOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :password,  :validates => [:confirmation_of]
end

class ValidatesPresenseOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :title,  :validates => [ :presense_of ]
end


class ValidatesLengthOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :title,  :validates => [[:length_of, { :minimum => 2 } ]]
end

class ValidatesFormatOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :title,  :validates => [[:format_of, { :with => /^\d+$/ } ]]
end

class ValidatesInclusionOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  number :age,  :validates => [[ :inclusion_of, { :in => 1..10 } ]]
end

class ValidatesExclusionOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  number :age,  :validates => [[ :exclusion_of, { :in => 1..10 } ]]
end

class ValidatesNumericalityOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  number :age,  :validates =>
    [[ :numericality_of, {
         :greater_than => 1,
         :odd          => true
       } ]]
end

class MultiValidationTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :title,  :validates => [[:each,      { :proc    => Proc.new{|record, attr, value|
                                      if value && value.length > 10
                                         record.errors.add(attr, "exceed 10 length")
                                      end
                                    } }],
                                 [:length_of, { :minimum => 5 } ],
                                 [:format_of, { :with    => /^\d+$/ }]]

end

class ValidatesChildrenOfTest
  include CouchResource::Struct
  include CouchResource::Validations
  string :title, :validates => [[:length_of, { :maximum => 10 }]]
  class NestedClass
    include CouchResource::Struct
    include CouchResource::Validations
    number :age,  :validates =>
      [[ :numericality_of, {
           :greater_than => 10,
           :odd          => true
         } ]]
  end
  object :nest, :is_a => NestedClass, :validates => [[:children_of, { :allow_nil => true }]]
end

class TestValidations < Test::Unit::TestCase
  def test_validates_each
    obj = ValidatesEachTest.new
    obj.first_name = "z"
    assert_equal false, obj.valid?
  end

  def test_validates_confirmation_of
    obj = ValidatesConfirmationOfTest.new
    obj.password = "z"
    obj.password_confirmation = "y"
    assert_equal false, obj.valid?
    obj.password_confirmation = "z"
    assert_equal true, obj.valid?
  end

  def test_validates_presense_of
    obj = ValidatesPresenseOfTest.new
    obj.title = nil
    assert_equal false, obj.valid?
    obj.title = "title"
    assert_equal true, obj.valid?
  end

  def test_validates_length_of
    obj = ValidatesLengthOfTest.new
    obj.title = "1"
    assert_equal false, obj.valid?
    obj.title = "123"
    assert_equal true, obj.valid?
  end

  def test_validates_format_of
    obj = ValidatesFormatOfTest.new
    obj.title = "1a"
    assert_equal false, obj.valid?
    obj.title = "11"
    assert_equal true, obj.valid?
  end

  def test_validates_inclusion_of
    obj = ValidatesInclusionOfTest.new
    obj.age = 5
    assert_equal true, obj.valid?
    obj.age = 11
    assert_equal false, obj.valid?
  end

  def test_validates_exclusion_of
    obj = ValidatesExclusionOfTest.new
    obj.age = 5
    assert_equal false, obj.valid?
    obj.age = 11
    assert_equal true, obj.valid?
  end

  def test_validates_numericality_of
    obj = ValidatesNumericalityOfTest.new
    obj.age = 2
    assert_equal false, obj.valid?
    obj.age = 3
    assert_equal true, obj.valid?
    obj.age = 1
    assert_equal false, obj.valid?
  end

  def test_multivalidation
    obj = MultiValidationTest.new
    obj.title = "a"
    assert_equal false, obj.valid?
    obj.title = "1"
    assert_equal false, obj.valid?
    obj.title = "aaaaaa"
    assert_equal false, obj.valid?
    obj.title = "111111"
    assert_equal true, obj.valid?
    obj.title = "11111111111"
    assert_equal false, obj.valid?
  end

  def test_validates_children_of
    obj = ValidatesChildrenOfTest.new
    obj.title = "1" * 15
    assert_equal false, obj.valid?
    obj.title = "1" * 5
    assert_equal true, obj.valid?
    obj.nest = ValidatesChildrenOfTest::NestedClass.new()
    obj.nest.age = 9
    assert_equal false, obj.valid?
    obj.nest.age = 11
    assert_equal true, obj.valid?

  end
end
