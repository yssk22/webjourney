#
# Abstract controller class to standardize controller behavior that response JSON/XML resources.
#
# == Using responders
#
# In the WebJourney standard, all the resources except HTML page is responded by using following methods as possible.
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
class WebJourney::ResourceController < WebJourney::ComponentController
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
end
