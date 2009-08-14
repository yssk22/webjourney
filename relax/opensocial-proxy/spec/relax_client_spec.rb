require 'rubygems'
require 'rack'
require File.join(File.dirname(__FILE__), "./spec_helper")
require File.join(File.dirname(__FILE__), "../lib/relax_client")

use_fixture

webjourney = RelaxClient.new("webjourney")
# opensocial = RelaxClient.new("opensocial")

describe RelaxClient, "get info" do
  it "should returns db information" do
    info = webjourney.info
    info["db_name"].should == "webjourney-default"
  end
end

describe RelaxClient, "saving a new document without the _id" do
  it "should return the saved document." do
    saved = webjourney.save({ "foo" => "bar" })
    saved.is_a?(Hash).should be_true
    saved["foo"].should == "bar"
    saved["_id"].should_not be_nil
    saved["_rev"].should_not be_nil
  end
end

describe RelaxClient, "saving a new document with the _id" do
  it "should return the saved document." do
    saved = webjourney.save({ "_id" => "relax_client_test_new_document",
                               "foo" => "bar" })
    saved.is_a?(Hash).should be_true
    saved["foo"].should == "bar"
    saved["_id"].should_not be_nil
    saved["_id"].should == "relax_client_test_new_document"
    saved["_rev"].should_not be_nil
  end
end

describe RelaxClient, "updating a document" do
  it "should return the updated document(new _rev number is assigned)." do
    saved = webjourney.save({ "_id" => "relax_client_test_new_document",
                               "foo" => "bar" })
    updated = webjourney.save(saved)
    updated["_rev"].should_not == saved["_rev"]
  end
end
