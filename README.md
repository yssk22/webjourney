# WebJourney - Document Oriented OpenSocial Platform powered by CouchDB

## REQUIREMENTS

* Apache HTTPD 2.2.7 or higher (with php+curl+openssl+mcrypt)
* Apache CouchDB 0.9.0

## INSTLLATION

### Check out sources.

    % git clone git://github.com/yssk22/webjourney.git
    % cd webjourney

### Configuration

Create .couchapprc file from dot_couchapprc(sample file) to configure database configuraitons.

    % cp relax/apps/webjourney/dot_couchapprc relax/apps/webjourney/.couchapprc
    % vi relax/apps/webjourney/.couchapprc

Create .htaccess file from dot_htaccess(sample file) to configure Apache Shindig.

    % cp site/dot_htaccess site/.htaccess
    % vi site/.htaccess

Configure your Apache Virtual Host settings for Shindig OpenSocial server and CouchDB proxy.
You must configure /opensocial as the Shindig web_prefix path.

    <VirtualHost *:80>
       ServerName {your hostname}
       DocumentRoot {your webjourney root}
       ErrorLog logs/webjourney_error_log
       AllowEncodedSlashes On
       ProxyRequests Off
       KeepAlive Off
       ProxyPass /opensocial !
       ProxyPass / http://{your couchdb host}:5984/ nocanon
       ProxyPassReverse / http://{your couchdb host}:5984/
       <Directory "{your webjourney root}">
          Options Indexes MultiViews FollowSymlinks
          AllowOverride All
          Allow from all
       </Directory>
    </VirtualHost>

### Import Initial Dataset

    % cd relax
    % rake initiailze

### Access the top page.

Go to http://{your hostname}/{your database name}/_design/webjourney/_show/page/pages:top

