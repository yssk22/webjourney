#
# WjPage is a CouchResource model that represents the metadata of the page and the included widgets.
# WjPage objects are stored in wj_pages database specified in config/couchdb.yml
#
# == Widget Instances Pointer and Instructions.
#
# The <tt>widgets</tt> property is a hash with (position, pointer arrays) pairs
# The pointer arrays specify the identifier of WjWidgetInstance.
# Each eleemnt in the pointer array specify the widget instance of the page, which has tree keys.
#
# <tt>:component</tt>::   a component name of the widget instance
# <tt>:widget</tt>::      a controller name of the widget instance
# <tt>:instnace_id</tt>:: an instance id of WjWidgetInstance
#
# To add/update/delete widget from the page, compose_widget_layout_hash method should be used.
#
# For example::
#
#   # create a new page
#   page = WjPage.create_new(WjUser.find_by_login_name("yssk22")
#
#   # a new widget (sticky/text) is added.
#   page.compose_widget_instance({ :center => [{:component => "sticky", :widget => "text"}] })
#   ## page.widgets[:center]
#   ## => [[{:component => "sticky", :widget => "text", :instance_id => "abcdefg" }]
#
#   page.save
#
#   # one more widget (stikey/html) is added.
#   # It is not supported to push pointer into widgets property so that
#   # recompose_widget_instance should be called.
#   page.widgets[:center] << {:component => "sticky", :widget => "html"}
#   page.recompose_widget_instance
#   ## page.widgets[:center]
#   ## => [{:component => "sticky", :widget => "text", :instance_id => "abcdefg"},
#   ##     {:component => "sticky", :widget => "html", :instance_id => "1234567"}]
#
#   page.save
#
#   # delete pointer
#   page.compose_widget_instance({})
#   page.save
#
#   # widget instances ("abcdefg" and "1234567") still remain in the database.
#   # To get them, use get_old_widget_instances.
#   # To clean them up, use clean_up_old_widget_instances
#   page.cleanup_old_widget_instances
#
# == BuiltIn Page
#
# The top page is configured when WebJourney is installed. It can be accessed by the identifier, 'top'.
#
# == Relationship Permission
#
# Each page has relationship keys for actions, which are 'show' and 'edit'.
# See also acts_as_relationship_permittable.
#
# == Properties
#
# === for head tags
#
# Following properties is to be used for head tags.
#
# <tt>title</tt>::         (rw) used for <title>.
# <tt>robots_index</tt>::  (rw) if flase, then <meta name="robots" content="noindex" /> is pushed.
# <tt>robots_follow</tt>:: (rw) if flase, then <meta name="robots" content="nofollow" /> is pushed.
# <tt>description</tt>::   (rw) used for the content attribute value of <meta name="description" />.
# <tt>keywords</tt>::      (rw) used for the content attribute value of <meta name="keywords" />. This property can be Array.
# <tt>copyright</tt>::     (rw) used for the content attribute value of <meta name="copyright" />.
#
# === for design
#
# <tt>width</tt>::        (rw) page width.
# <tt>width_unit</tt>::   (rw) unit string for <tt>width</tt>. one of WjConfig::DesignWidthUnits.
# <tt>lwidth</tt>::       (rw) left container width.
# <tt>lwidth_unit</tt>::  (rw) unit string for <tt>lwidth</tt>. one of WjConfig::DesignWidthUnits.
# <tt>rwidth</tt>::       (rw) right container width.
# <tt>rwidth_unit</tt>::  (rw) unit string for <tt>rwidth</tt>. one of WjConfig::DesignWidthUnits.
#
# === other properties
#
# <tt>created_at</tt>::       (r)  first time when the page is created.
# <tt>updated_at</tt>::       (r)  latest time when the page is updated.
# <tt>owner_login_name</tt>:: (rw) the owner login name of the page.
#
# === widgets
#
# <tt>widgets</tt>::          (r)  (position, pointer array) Hash
#
class WjPage < CouchResource::Base
  # The built-in identifier (<tt>_id</tt> value) for the top page.
  TopPageId = "top"
  JS_MAP_WIDGET_INSTANCES   = include_js("wj_page/map_widget_instances.js")
  JS_FUN_FILTER_INSTANCES   = include_js("wj_page/fun_filter_instances.js")
  JS_FUN_FIND_JOIN_KEYS     = include_js("wj_page/fun_find_join_keys.js")

  set_database CouchConfig.database_uri_for(:db => :wj_pages)
  acts_as_relationship_permittable({
                                     :show => {:all => true,  :tags => []},
                                     :edit => {:all => false, :tags => []}
                                   })
  # define width, :lwidth, :rwidth, and these units .
  [:width, :lwidth, :rwidth].each do |attr|
    number attr, :default => Proc.new { WjConfig["design_#{attr}"] },
    :validates => [[:numericality_of, { :only_integer => true, :allow_nil => false}]]
    string "#{attr}_unit", :default => Proc.new { WjConfig["design_#{attr}_unit"] },
    :validates => [[:inclusion_of,    { :in => WjConfig::DesignWidthUnits }]]
  end

  string :title,       :default => Proc.new{ "* NewPage * -- #{WjConfig["site_title"]}" },
  :validates => [[:length_of, {:in => 1..128, :allow_nil => false}]]

  string :copyright,   :default => Proc.new{ WjConfig["site_copyright"] },
  :validates => [[:length_of, {:in => 1..64,  :allow_nil => true} ]]

  string :description, :default => "* New Page Description *"
  boolean :robots_index,   :default => Proc.new { WjConfig[:site_robots_index] }
  boolean :robots_follow,  :default => Proc.new { WjConfig[:site_robots_follow] }

  array  :keywords,        :default => Proc.new { (WjConfig[:site_keywords] || "").split(",") }
  string :owner_login_name, :validates => [:presense_of]
  datetime :created_at
  datetime :updated_at

  object :widgets

  view :widget_instances, {
    :all_by_page => {
      :map    => JS_MAP_WIDGET_INSTANCES
    },
    :current_by_page => {
      :map    => JS_MAP_WIDGET_INSTANCES,
      :reduce => include_js("wj_page/widget_instances_current_by_page.reduce.js")
    },
    :old_by_page => {
      :map    => JS_MAP_WIDGET_INSTANCES,
      :reduce => include_js("wj_page/widget_instances_old_by_page.reduce.js")
    }
  }

  view :list,
  :by_owner_and_created_at => { :map => include_js("wj_page/list_by_owner_and_created_at.map.js") },
  :by_updated_at           => { :map => include_js("wj_page/list_by_updated_at.map.js") },
  :by_title                => { :map => include_js("wj_page/list_by_title.map.js") }

  # Returns the top page object.
  def self.top
    self.find(TopPageId)
  end

  # Create a new page for the <tt>user</tt>
  def self.create_new(user)
    user = user.is_a?(WjUser) ? user : WjUser.find_by_login_name(user.to_s)
    page = self.default
    page.owner_login_name = user.login_name
    # [TODO] feature : template page
    # [TODO] robustness: following statements should be executed in one transaction!
    page.save!
    page.compose_widget_instance_layout({:center => [{:component => "sticky", :widget => "html"}]})
    page.save!
    page
  end

  # Returns "my page" object for the <tt>user</tt>.
  # "my page" means the oldest page which is created by the <tt>user</tt>.
  # if "my page" is not found and the second argument, <tt>create</tt>, is true, then a new page is created.
  def self.my_page_for(user, create = false)
    user = user.is_a?(WjUser) ? user : WjUser.find_by_login_name(user.to_s)
    page = self.find_list_by_owner_and_created_at(:first,
                                                  :startkey => [user.login_name],
                                                  :endkey   => [user.login_name, "\u0000"],
                                                  :count    => 1)
    return page if page
    return nil  unless create
    # create a new my page for the user.
    page = self.default
    page.owner_login_name = user.login_name
    page.title       = "#{user.display_name}'s home"
    page.description = "This page is #{user.display_name}'s home page."
    # [TODO] robustness: following statements should be executed in one transaction!
    # assign page id
    page.save!
    # assign new widgets
    page.compose_widget_instance_layout({:center => [{
                                                       :component => "sticky", :widget => "html",
                                                     }]
                                        })
    # update widget instances layout_hash
    page.save!
    # set initial message
    display = page.widget_instances(:center).first
    display.title = "#{user.display_name}'s home"
    display.parameters[:html] = "<p>This page is automatically generated. Click edit to conpose widgets.</p>"
    display.save!
    page
  end

  # Returns true if the <tt>user</tt> can create a WjPage instance
  def self.allow_to_create?(user)
    user = user.is_a?(WjUser) ? user : WjUser.find_by_login_name(user.to_s)
    !user.is_anonymous? && user.is_active?
  end

  # Returns the WjUser object related to the <tt>owner_login_name</tt> property.
  def owner
    @_owner ||= WjUser.find_by_login_name(self.owner_login_name)
  end

  # Returns true if the <tt>user</tt> can read this page.
  def shown_to?(user)
    self.permit_relationship_of?(user, :show)
  end
  alias :allow_to_show? :shown_to?

  # Returns true if the <tt>user</tt> can update this page.
  def updated_by?(user)
    self.permit_relationship_of?(user, :edit)
  end
  alias :allow_to_update? :updated_by?

  # Returns true if the <tt>user</tt> can delete this page.
  def deleted_by?(user)
    self.owner_login_name == user.login_name
  end
  alias :allow_to_delete? :deleted_by?


  # Returns the stylesheet string of the left container width.
  def left_container_width()
    "#{self[:lwidth]}#{self[:lwidth_unit]}"
  end

  # Returns the stylesheet string of the right container width.
  def right_container_width()
    "#{self[:rwidth]}#{self[:rwidth_unit]}"
  end

  # Returns the WjWidgetInstance objects in the page.
  # The <tt>position</tt> parameter should be one of <tt>:top</tt>, <tt>:left</tt>, <tt>:center</tt>, <tt>:right</tt>, <tt>:bottom</tt>, or <tt>:all</tt>.
  # When the <tt>:all</tt> is passed, the return value is a HashWithIndifferentAccess object as follows::
  #
  #   { :top    => [...],
  #     :left   => [...],
  #     :center => [...],
  #     :right  => [...],
  #     :bottom => [...] }
  #
  # Otherwise, the return value is an Array.
  #
  def widget_instances(position = :all)
    case position
    when :top, :left, :right, :center, :bottom
      WjWidgetInstance.find(self.widgets[position].map{ |w| w[:instance_id] })
    when :all
      hash = HashWithIndifferentAccess.new({ :top => [], :left => [], :center => [], :right => [], :bottom => []})
      instance_ids = hash.keys.inject([]){ |ids, pos| ids << self.widgets[pos].map{ |w| w[:instance_id] } }.flatten!
      # if no instance ids are available, then return
      return hash if instance_ids.length == 0
      # some instance ids are found. get the (instance_id, instance) pairs.
      instances = WjWidgetInstance.find(instance_ids).inject({}){ |h, instance| h[instance.id] = instance; h}
      self.widgets.inject(hash){ |hash, pos_widgets|
        pos = pos_widgets.first.to_sym
        if pos_widgets.last
          hash[pos] = pos_widgets.last.map { |w| instances[w[:instance_id]]}
        else
          hash[pos] = []
        end
        hash
      }
    else
      raise ArgumentError.new("position must be one of :top, :left, :center, right, :bottom, or :all.")
    end
  end


  # Returns deleted widget instances which are no longer associated with the page.
  # This method is to be used to clean up defunct widgtes.
  def get_old_widget_instances()
    result = self.class.find_widget_instances_old_by_page(:return_raw_hash => true,
                                                          :startkey        => [self._id],
                                                          :endkey          => [self._id, 1],
                                                          :group           => true,
                                                          :group_level     => 1,
                                                          :descending      => false)
    instantize_widget_instances_result(result)
  end

  # Compose <tt>widgets</tt> properties with creating new WjWidgetInstance objects if not exists.
  # The <tt>layout_hash</tt> parameters ::
  #
  #   { :top    => [array of widget instance pointer],
  #     :left   => [...],
  #     :right  => [...],
  #     :center => [...],
  #     :bottom => [...] }
  #
  # And the widget instance <tt>pointer</tt> is as follows ::
  #
  #   # a instance created newly.
  #   { :component => "component name", :widget => "widget name" }
  #
  # or
  #
  #   # a instance which already exists
  #   { :instance_id => "XXXXXXX", :component => "component name", :widget => "widget name" }
  #
  # This method update the <tt>widgets</tt> property but it is not stored in the database.
  # To save <tt>widgets</tt> in the database, use save method, otherwise, newly created widget instances will be defunct widgets.
  def compose_widget_instance_layout(layout_hash)
    wj_widget = {}  # widget definition record cache
    widgets = {}
    [:top, :center, :left, :right, :bottom].each do |l|
      unless layout_hash.has_key?(l) # clean up
        widgets[l] = []
      else
        widgets[l] = layout_hash[l].map {|p| verify_and_update_pointer(p, wj_widget)}
      end
    end
    # update widgets parameter
    self.widgets = widgets
  end

  # The same as compose_widget_instance_layout(self.widgets)
  def recompose_widget_instance_layout
    self.compose_widget_instance_layout(self.widgets)
  end

  # Clean up widget instances that is no longer layouted.
  def clean_up_old_widget_instances
    bulk = get_widget_instances(:old).map do |instance|
      { :_id  => instance._id,
        :_rev => instance._rev,
        :_deleted => true }
    end
    self.class.bulk_docs(bulk)
  end


  private
  def instantize_widget_instances_result(result)
    first = result[:rows].first
    last  = result[:rows].last
    if first
      list = result[:rows].first[:value] || []
      # initialize
      list.select { |row| row[:joinkeys].nil? }.map { |obj|
        WjWidgetInstance.new(obj)
      }
    else
      []
    end
  end

  def verify_and_update_pointer(pointer, wj_widget)
    raise ArgumentError.new("missing key(:component) in the widget instance pointer") unless pointer.has_key?(:component)
    raise ArgumentError.new("missing key(:component) in the widget instance pointer") unless pointer.has_key?(:widget)
    return pointer if pointer.has_key?(:instance)
    # create a new instance
    key = File.join(pointer[:component], pointer[:widget])
    wj_widget[key] ||= WjWidget.get(pointer[:component], pointer[:widget])
    instance = wj_widget[key].build_new_instance(self)
    instance.save!
    # and return a new pointer
    {
      :component   => instance.component,
      :widget      => instance.widget,
      :instance_id => instance._id
    }
  end

=begin
  # Get all widget instances associated in the page
  # def get_all_widget_instances
  #   result = self.class.find_widget_instances_all_by_page(:return_raw_hash => false,
  #                                                        :key             => [self._id, 1],
  #                                                        :descending      => false)
  #  result[:rows]
  # end

  # Get widget instances layout in the page. This method does NOT assure the order of widget instances.
  # To get the instances by correct order, use WjPage#widget_instances(position)
  #def get_current_widget_instances()
  #  result = self.class.find_widget_instances_current_by_page(:return_raw_hash => true,
  #                                                            :startkey    => [self._id, 0],
  #                                                            :endkey      => [self._id, 1],
  #                                                            :group       => true,
  #                                                            :group_level => 1,
  #                                                            :descending  => false)
  #  instantize_widget_instances_result(result)
  #end
=end

end
