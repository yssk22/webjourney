{"gadgets.container" : ["myContainer"],

// Set of regular expressions to validate the parent parameter. This is
// necessary to support situations where you want a single container to support
// multiple possible host names (such as for localized domains, such as
// <language>.example.org. If left as null, the parent parameter will be
// ignored; otherwise, any requests that do not include a parent
// value matching this set will return a 404 error.
"gadgets.parent" : null,

// Should all gadgets be forced on to a locked domain?
"gadgets.lockedDomainRequired" : false,

// DNS domain on which gadgets should render.
"gadgets.lockedDomainSuffix" : "-a.example.com:8080",

// Various urls generated throughout the code base.
// iframeBaseUri will automatically have the host inserted
// if locked domain is enabled and the implementation supports it.
// query parameters will be added.
"gadgets.iframeBaseUri" : "/gadgets/ifr",

// jsUriTemplate will have %host% and %js% substituted.
// No locked domain special cases, but jsUriTemplate must
// never conflict with a lockedDomainSuffix.
"gadgets.jsUriTemplate" : "http://%host%/gadgets/js/%js%",

// Callback URL.  Scheme relative URL for easy switch between https/http.
"gadgets.oauthGadgetCallbackTemplate" : "//%host%/gadgets/oauthcallback",

// Use an insecure security token by default
"gadgets.securityTokenType" : "insecure",

// Config param to load Opensocial data for social
// preloads in data pipelining.  %host% will be
// substituted with the current host.
"gadgets.osDataUri" : "http://%host%/social/rpc",

// Uncomment these to switch to a secure version
//
//"gadgets.securityTokenType" : "secure",
//"gadgets.securityTokenKeyFile" : "/path/to/key/file.txt",

// This config data will be passed down to javascript. Please
// configure your object using the feature name rather than
// the javascript name.

// Only configuration for required features will be used.
// See individual feature.xml files for configuration details.
"gadgets.features" : {
  "core.io" : {
    // Note: /proxy is an open proxy. Be careful how you expose this!
    "proxyUrl" : "http://%host%/gadgets/proxy?refresh=%refresh%&url=%url%",
    "jsonProxyUrl" : "http://%host%/gadgets/makeRequest"
  },
  "views" : {
    "profile" : {
      "isOnlyVisible" : false,
      "urlTemplate" : "http://localhost/gadgets/profile?{var}",
      "aliases": ["DASHBOARD", "default"]
    },
    "canvas" : {
      "isOnlyVisible" : true,
      "urlTemplate" : "http://localhost/gadgets/canvas?{var}",
      "aliases" : ["FULL_PAGE"]
    }
  },
  "rpc" : {
    // Path to the relay file. Automatically appended to the parent
    /// parameter if it passes input validation and is not null.
    // This should never be on the same host in a production environment!
    // Only use this for TESTING!
    "parentRelayUrl" : "/gadgets/files/container/rpc_relay.html",

    // If true, this will use the legacy ifpc wire format when making rpc
    // requests.
    "useLegacyProtocol" : false
  },
  // Skin defaults
  "skins" : {
    "properties" : {
      "BG_COLOR": "",
      "BG_IMAGE": "",
      "BG_POSITION": "",
      "BG_REPEAT": "",
      "FONT_COLOR": "",
      "ANCHOR_COLOR": ""
    }
  },
  "opensocial-0.8" : {
    // Path to fetch opensocial data from
    // Must be on the same domain as the gadget rendering server
    "path" : "http://%host%",
    "domain" : "shindig",
    "enableCaja" : false,
    "supportedFields" : {
       "person" : ["id", {"name" : ["familyName", "givenName", "unstructured"]}, "thumbnailUrl", "profileUrl"],
       "activity" : ["id", "title"]
    }
  },
  "osapi.services" : {
    // Specifying a binding to "container.listMethods" instructs osapi to dynamicaly introspect the services
    // provided by the container and delay the gadget onLoad handler until that introspection is
    // complete.
    // Alternatively a container can directly configure services here rather than having them
    // introspected. Simply list out the available servies and omit "container.listMethods" to
    // avoid the initialization delay caused by gadgets.rpc
    // E.g. "gadgets.rpc" : ["activities.requestCreate", "messages.requestSend", "requestShareApp", "requestPermission"]
    "gadgets.rpc" : ["container.listMethods"]
  },
  "osapi" : {
    // The endpoints to query for available JSONRPC/REST services
    "endPoints" : [ "http://%host%/social/rpc", "http://%host%/gadgets/api/rpc" ]
  },
  "osml": {
    // OSML library resource.  Can be set to null or the empty string to disable OSML
    // for a container.
    "library": "config/OSML_library.xml"
  }
}}
