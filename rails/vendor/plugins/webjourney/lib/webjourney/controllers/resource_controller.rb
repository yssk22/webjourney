#
# Abstract controller class to standardize controller behavior that response JSON/XML resources.
#
# == Standardized REST using responders
#
# ===  Resource Representation
#
# - A resource object should have two methods, <tt>to_xml</tt> and <tt>to_json</tt>.
# - A resource object should be compatible for Hash object.
# - A resource should be as following expression (in Hash)::
#
#
# === Utility methods
# To standardize resource representation,
# all the resources except HTML page should be responded by using following methods as possible.
#
# - respond_to_ok(resource)
# - respond_to_created(resource)
# - respond_to_error(resource)
# - respond_to_resource(resource, status)
#
# The <tt>resource</tt> should have two methods, to_xml and to_json.
# The general responder instruction in the controller is as follows::
#
#   def show
#     @resource = Resource.find(...)
#     respond_to_ok(@resource)
#   end
#
#   def update
#     @resource = Resource.find(...)
#     if @resource.save
#       respond_to_ok(@resource)
#       # or respond_to_nothing()
#     else
#       respond_to_error(@resource.errors)
#     end
#   end
#
class WebJourney::ResourceController < WebJourney::ApplicationController
  before_filter do |controller|
    controller.request.format = :json   # set default format json.
  end

  # Response resource with 200
  def respond_to_ok(resource)
    respond_to_resource(resource, 200)
  end

  # Response resource with 201
  def respond_to_created(resource)
    respond_to_resource(resource, 201)
  end

  # Response resource with 400
  def respond_to_error(resource)
    respond_to_resource(resource, 400)
  end

  # Response blank with <tt>status</tt>.
  def respond_to_nothing(status=200)
    respond_to do |format|
      format.xml  { render :nothing => true, :status => status }
      format.json { render :nothing => true, :status => status }
    end
  end

  # Response <tt>resource</tt> with <tt>status</tt>.
  def respond_to_resource(resource, status)
    return respond_to_nothing(status) if resource.blank?
    respond_to do |format|
      format.xml  { render :text => resource.to_xml,  :status => status } if resource.respond_to?(:to_xml)
      format.json { render :text => resource.to_json, :status => status } if resource.respond_to?(:to_json)
    end
  end

  # Returns a hash containing all of error message for the objects.
  # the resource is as following formats::
  #
  #   {
  #      :object_name => {
  #          :errors     => [msg1, msg2, ...],   # if base errors exist.
  #          :attr_name1 => [msg1, msg2, ...],   # errors for attribtues.
  #          :attr_name2 => [msg1, msg2, ...],   # errors for attribtues.
  #          ...
  #      }
  #   }
  def error_resource_for(*params)
    options = params.extract_options!.symbolize_keys
    if object = options.delete(:object)
      object_name = options[:object_name]
      raise ArgumentError.new(":object and :object_name must be used both.") if object_name.blank?
      objects = [[object, object_name]].flatten
    else
      objects = params.collect {|object_name|
        [instance_variable_get("@#{object_name.to_s}"), object_name]
      }
    end
    resource = {}
    objects.each do |object, object_name|
      next if object.errors.count == 0
      errors_by_attr = {}
      base_errors = []
      object.errors.each do |attr, msg|
        next if msg.blank?
        if attr == "base"
          base_errors << msg
        else
          errors_by_attr[attr]||= []
          errors_by_attr[attr] << (object.class.human_attribute_name(attr) + " " + msg)
        end
      end
      attr_errors[:errors] = base_errors if base_errors.length > 0
      resource[object_name] = errors_by_attr
    end

    resource
  end
end
