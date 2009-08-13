require File.join(File.dirname(__FILE__), "../lib/security_token")
#
# Generate security token for spec test
#
def security_token(viewer_id, option = { })
  option = {
    :owner_id  => viewer_id,
    :app_id    => "test",
    :domain_id => "example.org",
    :app_url   => "http://example.org/test.xml",
    :module_id => "test",
    :time      => 0
  }.update(option)
  SecurityToken.new(viewer_id,
                    option[:owner_id],
                    option[:app_id],
                    option[:domain_id],
                    option[:app_url],
                    option[:module_id],
                    option[:time])
end
