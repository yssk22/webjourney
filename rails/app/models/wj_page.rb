class WjPage < CouchResource::Base
  set_database CouchConfig.database_uri_for(:db => :wj_pages)
  TopPageId = "top"
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
  object :widgets
  string :owner_login_name, :validates => [:presense_of]
  datetime :created_at
  datetime :updated_at

  # inner JS function used in widget_instances view
  JS_WIDGET_INSTANCES_MAP = <<-EOS
function(doc) {
   if( doc.class == "WjPage") {
     var joinkeys =  {};
     if( doc.widgets ){
        for(var l in doc.widgets){
          for(var i in doc.widgets[l] ){
             joinkeys[doc.widgets[l][i].instance_id] = true;
          }
        }
     }
     emit([doc._id, 0], {joinkeys : joinkeys});
   }
   if( doc.class == "WjWidgetInstance") {
     emit([doc.wj_page_id, 1], doc);
   }
}
EOS

  JS_FIND_JOIN_KEYS = <<-EOS
  function findJoinKeys(list){
    for(var i in list){
       if( list[i].joinkeys ){
          return list[i];
       }
    }
    return null;
  }
EOS
  JS_FILTER_INSTANCES = <<-EOS
  function filterInstances(list, joinkeys, include){
     var matched = [];
     for(var i=0; i<list.length; i++){
       var instance = values[i];
       if( instance._id ){
         if( include ){
           if( joinkeys.joinkeys[instance._id] ){
             matched.push(instance);
           }
         }else{
           if( !joinkeys.joinkeys[instance._id] ){
             matched.push(instance);
           }
         }
       }
     }
     return matched;
  }
EOS

  view :widget_instances, {
    :all_by_page => {
      :map => JS_WIDGET_INSTANCES_MAP
    },
    :current_by_page => {
      :map => JS_WIDGET_INSTANCES_MAP,
      :reduce => <<-EOS
function(keys, values, rr){
#{JS_FIND_JOIN_KEYS}
#{JS_FILTER_INSTANCES}
  if( values.length > 0 ){
     var joinkeys = findJoinKeys(values);
     if( joinkeys ){
        var matched = filterInstances(values, joinkeys, true);
        matched.unshift(joinkeys);
        return matched;
     }
     else{
       return values;
     }
  }
  else{
     return [];
  }
}
EOS
    }, # end of :by_page
    :old_by_page => {
      :map => JS_WIDGET_INSTANCES_MAP,
      :reduce => <<-EOS
function(keys, values, rr){
#{JS_FIND_JOIN_KEYS}
#{JS_FILTER_INSTANCES}
  if( values.length > 0 ){
     var joinkeys = findJoinKeys(values);
     if( joinkeys ){
        var matched = filterInstances(values, joinkeys, false);
        matched.unshift(joinkeys);
        return matched;
     }
     else{
       return values;
     }
  }
  else{
     return [];
  }
}
EOS
    }, # end of :deads_by_page
  } # end of :widget_instances

  view :by_owner_and_created_at, :all => {
    :map => <<-EOS
function(doc) {
  if(doc.class == "WjPage"){
    emit([doc.owner_login_name, doc.created_at], doc)
  }
}
EOS
  }

  view :list, :by_updated_at => {
    :map => <<-EOS
function(doc){
   if( doc.class == "WjPage"){
    emit(doc.updated_at, doc)
   }
}
EOS
  }, :by_title => {
    :map => <<-EOS
function(doc){
   if( doc.class == "WjPage"){
    emit(doc.title, doc)
   }
}
EOS
  }

  def self.top
    self.find(TopPageId)
  end

  def self.create_new_page(user)
    u = user.is_a?(WjUser) ? user : WjUser.find_by_login_name(user.to_s)
    page = self.default
    page.owner_login_name = u.login_name
    # [TODO] feature : template page
    # [TODO] robustness: following statements should be executed in one transaction!
    page.save!
    page.compose_widget_instance_layout({:center => [{
                                                       :component => "sticky", :widget => "html",
                                                     }]
                                        })
    page.save!
    page
  end

  # Get the my page which is the oldest page created by the <tt>user</tt>
  def self.my_page_for(user)
    u = user.is_a?(WjUser) ? user : WjUser.find_by_login_name(user.to_s)
    page = self.find_by_owner_and_created_at_all(:first, :startkey => [u.login_name], :count => 1)
    unless page
      page = self.default
      page.owner_login_name = u.login_name
      page.title = "#{u.display_name}'s home"
      page.description = "this page is #{u.display_name}'s home page."
      # [TODO] robustness: following statements should be executed in one transaction!
      # assign page id
      page.save!
      # assign new widgets
      page.compose_widget_instance_layout({:center => [{
                                                         :component => "sticky", :widget => "html",
                                                       }]
                                          })
      # update widget instances layout
      page.save!
    end
    page
  end

  # Return true if the <tt>user</tt> can create a WjPage instance
  def self.created_by?(user)
    !user.is_anonymous? && user.is_active?
  end

  # Get the WjUser object related to the <tt>:owner_login_name</tt> property.
  def owner
    @_owner ||= WjUser.find_by_login_name(self.owner_login_name)
    @_owner
  end

  # Get the width of the left container.
  def left_container_width()
    "#{self[:lwidth]}#{self[:lwidth_unit]}"
  end

  # Get the width of the right container.
  def right_container_width()
    "#{self[:rwidth]}#{self[:rwidth_unit]}"
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

  # Get widget instances associated in the page.
  # <tt>target</tt> value should be possible as follows::
  #   <tt>:all</tt>     - widget instances both current and old.
  #   <tt>:current</tt> - widget instances currently layouted in this page.
  #   <tt>:old</tt>     - widget instances past layouted in this page.
  #
  def get_widget_instances(target = :all)
    case target
      when :all
        get_all_widget_instances
      when :current
        get_current_widget_instances
      when :old
        get_old_widget_instances
      else
        raise ArgumentError.new("target should be one of :all, :current or :old.")
    end
  end

  # Get all widget instances associated in the page
  def get_all_widget_instances
    # by_page?startkey=["top", 0]&endkey=["top",1]&group=true&descending=false
    result = self.class.find_widget_instances_all_by_page(:return_raw_hash => false,
                                                          :key             => [self._id, 1],
                                                          :descending      => false)
    result[:rows]
  end

  # Get all widget instances layout in the page.
  def get_current_widget_instances()
    # by_page?startkey=["top", 0]&endkey=["top",1]&group=true&descending=false
    result = self.class.find_widget_instances_current_by_page(:return_raw_hash => true,
                                                              :startkey    => [self._id, 0],
                                                              :endkey      => [self._id, 1],
                                                              :group       => true,
                                                              :group_level => 1,
                                                              :descending  => false)
    instantize_widget_instances_result(result)
  end

  # Get all widget instances no longer associated to the old version of this page.
  def get_old_widget_instances()
    # by_page?startkey=["top", 0]&endkey=["top",1]&group=true&descending=false
    result = self.class.find_widget_instances_old_by_page(:return_raw_hash => true,
                                                          :startkey    => [self._id, 0],
                                                          :endkey      => [self._id, 1],
                                                          :group       => true,
                                                          :group_level => 1,
                                                          :descending  => false)
    instantize_widget_instances_result(result)
  end

  # Compose WjWidgetInstances following to <tt>layout_hash</tt>
  # The <tt>layout_hash</tt> parameters ::
  #
  #  { :top    => [array of widget instance pointer],
  #    :left   => [...],
  #    :right  => [...],
  #    :center => [...],
  #    :bottom => [...] }
  #
  # And the widget instance pointer is as follows ::
  #
  #  # a instance created newly.
  #  { :component => "component name", :widget => "widget name" }
  #
  # or
  #  # a instance which already exists
  #  { :instance_id => "XXXXXXX", :component => "component name", :widget => "widget name" }
  #
  def compose_widget_instance_layout(layout_hash)
    wj_widget = {}  # widget definition record cache
    widgets = {}
    [:top, :center, :left, :right, :bottom].each do |l|
      if layout_hash[l]
        widgets[l] = layout_hash[l].map do |pointer|
          if pointer[:instance_id]
            # nothing to do
            pointer
          else
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
        end
      else
        widgets[l] = []
      end
    end
    # update widgets parameter
    self.widgets = widgets
  end

  # Return true if the <tt>user</tt> can read this page.
  def shown_to?(user)
    self.permit_relationship_of?(user, :show)
  end

  # Return true if the <tt>user</tt> can update this page.
  def updated_by?(user)
    self.permit_relationship_of?(user, :edit)
  end

  # Return true if the <tt>user</tt> can delete this page.
  def deleted_by?(user)
    self.owner_login_name == user.login_name
  end


  private
  def instantize_widget_instances_result(result)
    if result[:rows].first
      list = result[:rows].first[:value] || []
      # initialize
      list.select { |row| row[:joinkeys].nil? }.map { |obj|
        WjWidgetInstance.new(obj)
      }
    else
      []
    end
  end
end
