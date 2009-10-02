namespace :print do
  desc("Print the VirtualHost configuration for Apache httpd.conf")
  task :httpd_conf do
    template_path = File.join(File.dirname(__FILE__), "config/httpd.template.conf")
    # setup binding parameters
    httpd = {
      "servername" => config["httpd"]["servername"],
      "docroot"    => Pathname.new(File.join(File.dirname(__FILE__), "site")).realpath
    }
    ERB.new(File.read(template_path), nil, '-').run(binding)
  end
end
