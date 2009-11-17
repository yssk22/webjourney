# WebJourney - Document Oriented OpenSocial Platform powered by CouchDB

# System Requirements

- Apache HTTP Server (2.2.0 or higher)
- Apache CouchDB (0.10.0, included in vendor directory)
- Apache Shindig (1.1, included in vendor directory)
- Ruby(1.8.6 or higher) and following gemes
 - rake (0.8.3)
 - json (1.1.9)
 - rest-client (1.0.3)
 - oauth (0.3.5)
 - (for development env only)
  - rack-test (0.4.2)
  - rcov (0.8.1.2.0)
  - rdoc (2.1.0)
  - rspec (1.2.8)
- Python 2.5 (or higher)
 - CouchApp (0.4)

# Getting Started

## configuration

### Modify default configuration

config/webjourney.json is a default configuration file for WebJourney.
You can overwrite this configration by putting config/webjourney.local.json file.

## Set up database.

On webjourney root directory, launch initialize task.

    $rake all:initialize

## Set up OpenSocial Proxy

You need to configure the proxy service on your Apache HTTP server.
The required httpd.conf contents are shown as following command:

    $rake print:httpd_conf

## Access your social site.

http://localhost/webjorney-default/top

