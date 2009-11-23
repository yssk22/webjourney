/**
* @fileoverview WebJourney Gadget Container (Page) implementation
**/
WebJourney.Page = WebJourney.Page || function(){
  this.initialize.apply(this, arguments);
};

WebJourney.Page.LOCATIONS = ["top", "bottom", "left", "right", "center"];
WebJourney.Page._DEFAULT_GADGET_LOCATION   = "center";
WebJourney.Page._NEW_UUID_CACHE_NUM = 5;
WebJourney.Page._GADGET_SORTABLE_OPTION =  {
  connectWith: ["div.container"],
  placeholder: "ui-state-highlight",
  handle     : "div.gadget-title-bar",
  scroll     : true,
  cursor     : "move",
  forcePlaceholderSize: true,
  cursorAt: { top: 20, left: 20 }
};
WebJourney.Page._ADD_GADGET_DIALOG_OPTION =  {
  width      : 800,
  height     : 600,
  autoOpen   : false,
  modal      : true,
  resizable  : false
};
WebJourney.Page._LOGIN_DIALOG_OPTION =  {
  width      : 600,
  height     : 400,
  autoOpen   : false,
  modal      : true,
  resizable  : false
};

WebJourney.Page._ADD_GADGET_DIALOG_TABS_OPTION =  {};
WebJourney.Page._LOGIN_DIALOG_TABS_OPTIONS = {};


WebJourney.Page.prototype = {
  /**
  * Page object that manages gadget containers.
  * @constructor
  * @param document Object document retrieved from Gadget Database by CouchDB.
  * @param app CouchApp application context.
  */
  initialize : function(document, app){
    var self = this;
    log("[Page#initialize] " + JSON.stringify(document));
    this._document = document;      // represents Page document stored in Couch
    this._app      = app;           // CouchApp instance
    this._editMode = false;         // indicates in-edit mode or not.
    this._changed  = false;         // set true when something changed.

    // UI Components Initialize
    this._message  = new WebJourney.Message("#page-message");
    jQuery("#add_gadget_dialog").dialog(WebJourney.Page._ADD_GADGET_DIALOG_OPTION);
    jQuery("#add_gadget_dialog_tabs").tabs(WebJourney.Page._ADD_GADGET_DIALOG_TABS_OPTION);
    jQuery("#login_dialog").dialog(WebJourney.Page._LOGIN_DIALOG_OPTION);
    jQuery("#login_dialog_tabs").tabs(WebJourney.Page._LOGIN_DIALOG_TABS_OPTION);
    jQuery("#login_auth form").bind("submit", function(){ self.onSubmitLoginAuth(); });

    // Gadget Initialize
    this._initializeGadgets();
    this._renderGadgets();
    this.refresh();
  },

  /**
  * Make the page mode to 'edit-mode'
  */
  edit : function(){
    this._editMode = true;
    this._changed  = false;
    this._initializeGadgets();
    this._renderGadgets();
    this.refresh();
  },

  /**
  * Make the page mode to 'show-mode'
  */
  cancelEdit : function(){
    if( this._changed ){
      if(!confirm("Discard changes?")){
        return; // cancel to cancel
      }
    }
    // reload the page
    window.location.href = window.location.href;
  },

  /**
  * Save the document to database
  */
  save : function(){
    log("[Page#save] --> " + JSON.stringify({"_id"  : this._document._id,
    "_rev" : this._document._rev}));
    var self = this;
    this._populateBoundDataFromGadgetBlocks();
    this._app.db.saveDoc(this._document, {
      error   :function(status, error, reason){
        log("[Page#save] <-- " + JSON.stringify({error: error, reason:reason}));
        alert("The document could not be saved: " + reason);
      },
      success :function(resp){
        log("[Page#save] <-- " + JSON.stringify(resp));
        self._changed = false;
        self._message.highlight("Updated successfully");
      }
    });
  },


  /**
  * Set _changed value to val.
  */
  setChanged : function(val){
    this._changed = val;
  },

  /**
  * Show Add Gadget Dialog
  */
  showAddGadgetDialog : function(){
    jQuery("#add_gadget_dialog").dialog("open");
    var url = this._app.listPath("add_gadget_from_directory", "all_apps_by_category");
    jQuery("#add_gadget_from_directory").load(url);
  },

  /**
  * Hide Add Gadget Dialog
  */
  hideAddGadgetDialog : function(){
    jQuery("#add_gadget_dialog").dialog("close");
  },

  /**
  * Show Login Dialog
  */
  showLoginDialog : function(){
    jQuery("#login_dialog").dialog("open");
  },

  /**
  * Hide Login Dialog
  */
  hideLoginDialog : function(){
    jQuery("#login_dialog").dialog("close");
  },

  /**
  * Add a gadget to this page.
  */
  addGadget : function(doc_or_uri){
    var xml_uri, module_prefs;
    if( doc_or_uri instanceof String ){
      // add external xml uri
      xml_uri = doc_or_uri;
      module_prefs = this.getModulePrefsFromURI(xml_uri);
    }else{
      // add internal application
      xml_uri      = doc_or_uri.gadget_xml;
      module_prefs = doc_or_uri;
      this._addGadget(xml_uri, module_prefs);
    }
    this.hideAddGadgetDialog();
  },

  /**
  * Delete a gadget on this page
  * @param WebJourney.Gadget a gadget instance to be deleted.
  */
  deleteGadget : function(gadget){
    this._deleteGadget(gadget);
  },

  /**
   *  login
   */
  login : function(){
    var form = jQuery("#login_dialog form");
    var user = jQuery("input[name='name']").val();
    var pass = jQuery("input[name='password']").val();
    var result = CouchDB.login(user, pass);
    if( result.ok ){
      // go to profile page.
      window.location.href = "../profile/" + user;
    }else{
      alert(result.reason);
    }
  },

  /**
   * logout
   */
  logout : function()
{
  },

  /**
  * Returns a location key and index
  */
  findGadgetLocationByGadgetId : function(gadget_id){
    for(var l in WebJourney.Page.LOCATIONS){
      var lkey = WebJourney.Page.LOCATIONS[l];
      var ids  = jQuery.map(this._gadgets[lkey], function(n, i){
        return n.getId();
      });
      var found = jQuery.inArray(gadget_id, ids);
      if(found >= 0){
        return {
          location : lkey,
          index : found
        };
      }
    }
    return null;
  },

  onSubmitLoginAuth : function(){
    this.login();
    return false;
  },

  onSubmitLoginRegister : function(){
    this.register();
    return false;
  },

  /**
  * Render the html documents.
  */
  _renderGadgets : function(lkey){
    if( lkey ){
      var location  = this.getContainerElement(lkey);
      // clear the location.
      location.html("");
      // initialize gadget block elements
      for(var i in this._gadgets[lkey]){
        var block = this._gadgets[lkey][i].createBlockObject();
        block.data("gadget_object", this._gadgets[lkey][i]); // binding gadget object to block
        block.appendTo(location);
      }
      // set edit-mode
      if( this._editMode ){
        location.addClass("container-edit-mode");
      }else{
        location.removeClass("container-edit-mode");
      }
    }else{
      // all
      for(var l in WebJourney.Page.LOCATIONS){
        this._renderGadgets(WebJourney.Page.LOCATIONS[l]);
      }
      if( this._editMode ){
        // make sortable
        var self = this;
        jQuery("div.container").sortable(
          jQuery.extend(WebJourney.Page._GADGET_SORTABLE_OPTION,
            {
              start  : function(e, ui){ jQuery(ui.helper).width("200px"); },
              stop   : function(e, ui){ jQuery(ui.helper).width("100%");  },
              update : function(e, ui){
                // synchronize gadget instance data
                self._populateBoundDataFromGadgetBlocks();
                self.setChanged(true);
              }
              }));
            }
            this.adjustLayout();
          }
        },

      /**
      * Refresh the page.
      */
      refresh : function(lkey){
        if( lkey ){
          // specified location
          var location  = this.getContainerElement(lkey);
          var html = "";
          for(var i in this._gadgets[lkey]){
            this._gadgets[lkey][i].refresh();
          }
        }else{
          // all
          // refresh the gadgets
          for(var l in WebJourney.Page.LOCATIONS){
            this.refresh(WebJourney.Page.LOCATIONS[l]);
          }
          // edit-mode link and buttons
          if( this._editMode ){
            $(".show-mode", location).hide();
            $(".edit-mode", location).show();
          }else{
            $(".edit-mode", location).hide();
            $(".show-mode", location).show();
          }
        }
      },

      /**
      * Adjust the width/margin of div block elements for gadget containers.
      */
      adjustLayout : function(){
        var left    = this.getContainerElement("left");
        var right   = this.getContainerElement("right");
        var center  = this.getContainerElement("center");
        var wrapper     = jQuery("#wrapper");
        var wrapperMain = jQuery("#wrapper-main");

        if( this._editMode ){
          left.show();
          right.show();
        }else{
          if( this._gadgets["left"].length == 0 ){
            left.hide();
          }
          if( this._gadgets["right"].length == 0 ){
            right.hide();
          }
        }

        var lwidth = left.css("display")  == "block" ? left.outerWidth(true)  : 0;
        var rwidth = right.css("display") == "block" ? right.outerWidth(true) : 0;
        wrapper.css("margin-right",    (-1) * rwidth);
        wrapperMain.css("margin-left", (-1) * lwidth);
        center.css("margin-right", rwidth > 0 ? rwidth + 10 : 0);
        center.css("margin-left",  lwidth > 0 ? lwidth + 10 : 0);
      },

      getContainerId : function(locationKey){
        return "#container-" + locationKey;
      },

      /**
      * Returns a jQuery Object matched with locationKey
      * @param locationKey {String} location key name, one of WebJourney.Page.LOCATIONS
      */
      getContainerElement : function(locationKey){
        return jQuery(this.getContainerId(locationKey));
      },

      /**
      * Returns a gadget rendering server base URI for iframe gadgets.
      */
      getServerBase : function(){
        // TODO make server base configurable (or automatically determined)
        return "http://webjourney.local/shindig/gadgets/";
      },

      /**
      * (Private) Initialize gadget objects for display
      */
      _initializeGadgets : function(lkey){
        if( lkey ){
          this._gadgets[lkey] = [];
          var gadgets = this._document.gadgets[lkey];
          if( gadgets instanceof Array && gadgets.length > 0){
            for(var i in gadgets){
              var gadget = new WebJourney.Gadget(this, gadgets[i]);
              this._gadgets[lkey][i] = gadget;
            }
          }
        }else{
          // all
          this._gadgets = {};
          for(var l in WebJourney.Page.LOCATIONS){
            this._initializeGadgets(WebJourney.Page.LOCATIONS[l]);
          }
        }
      },

      /**
      * (Private)
      * This method synchronize this._document.gadgets data and this._gadgets data from currently rendered elements.
      */
      _populateBoundDataFromGadgetBlocks : function(){
        var gadget_parameters = {};
        var gadget_objects    = {};
        for(var l in WebJourney.Page.LOCATIONS){
          var lkey = WebJourney.Page.LOCATIONS[l];
          var location  = this.getContainerElement(lkey);
          gadget_parameters[lkey] = [];
          gadget_objects[lkey]    = [];
          jQuery("div.gadget", location)
          .each(function(index){
            var block = jQuery(this);
            var gadget_object = block.data("gadget_object");
            gadget_objects[lkey].push(gadget_object);
            gadget_parameters[lkey].push(gadget_object.getParameter());
          });
        }
        this._document.gadgets = gadget_parameters;
        this._gadgets = gadget_objects;
      },

      /**
      * (Private) Add a gadget to this page.
      */
      _addGadget : function(xml_uri, xml){
        var gadget = {
          url : xml_uri,
          id  : $.couch.newUUID(WebJourney.Page._GADGET_NEW_UUID_CACHE_NUM)
        };
        // ModulePrefs
        gadget.title = xml.module_prefs._attrs.title;
        gadget.title_url = xml.module_prefs._attrs.title_url;
        // TODO setting UserPrefs

        // assing ModuleId using UUID
        // add gadget object on the document.
        var lkey = WebJourney.Page._DEFAULT_GADGET_LOCATION;
        if( this._document.gadgets[lkey] == undefined ){
          this._document.gadgets[lkey] = [];
        }
        // insert a new gadget definition.
        this._document.gadgets[lkey].unshift(gadget);

        // rebuild Gadget Instance on the lkey location
        this._initializeGadgets(lkey);
        this._renderGadgets(lkey);
        this.refresh(lkey);
        this.setChanged(true);
      },

      _deleteGadget : function(gadget){
        var found =  this.findGadgetLocationByGadgetId(gadget.getId());
        if( found ){
          var lkey = found.location;
          var index = found.index;
          // remove the definition;
          this._document.gadgets[lkey].splice(index, 1);
          // rebuild gadget instance
          this._initializeGadgets(lkey);
          this._renderGadgets(lkey);
          this.refresh(lkey);
          this.setChanged(true);
        }
      }

    };
