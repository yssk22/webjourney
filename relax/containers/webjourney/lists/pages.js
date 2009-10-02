function(head, row, req) {
  // !code vendor/couchapp/path.js

  respondWith(req, {
    html : function() {
      if (head) {
        return '<html><h1>All Pages</h1> total pages: '+ head.total_rows +'<ul/>';
      } else if (row) {
        return '\n<li><a href="' + assetPath() + "/_show/page/" + row.id + '">' + row.value.title  + '</a></li>';
      } else {
        return '</ul></html>';
      }
    }
  });
};