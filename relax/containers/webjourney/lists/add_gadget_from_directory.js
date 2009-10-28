/**
 * Display a list for add gadget from directory dialog.
 *
 * Supported Views:
 *    - all_apps_by_category
 */
function(head, req) {
  // !code lib/helpers/util.js
  // !code vendor/ejs/ejs_production.js
  // !code vendor/couchapp/template.js
  // !code vendor/couchapp/path.js
  // !json templates.add_gadget_from_directory.head
  // !json templates.add_gadget_from_directory.row
  // !json templates.add_gadget_from_directory.tail
  provides("html", function(){
             var ejs = new EJS({text: templates.add_gadget_from_directory.head});
             send(ejs.render({}));
             var row;
             while(row = getRow()){
               ejs = new EJS({text: templates.add_gadget_from_directory.row});
               send(ejs.render({
                                 doc: row.value,
                                 image_path : row.value["gadget_image"] || (assetPath() + "/images/no_image_gadget.png")
                               }));
             }
             ejs = new EJS({text: templates.add_gadget_from_directory.tail});
             send(ejs.render({}));
           });
}