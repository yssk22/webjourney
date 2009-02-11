class WjUser
  #
  # OpenID user class implementation.
  #
  class OpenId < WjUser
    validates_format_of :open_id_uri, :with => /http(s?):\/\/[^\/:]+/, :allow_nil => false

    def self.prepare(login_name, open_id_uri)
      obj = self.new()
      obj.open_id_uri = open_id_uri
      obj.login_name = login_name
      obj.status = WjUser::Status[:prepared]
      if obj.save
        logger.wj_info("OpenID user (#{login_name},#{open_id_uri}) prepared.")
      end
      obj
    end

    # GEt the login method to display
    def login_method; "OpenID"; end

    def activate
      unless self.active?
        self.status = WjUser::Status[:active]
        self.wj_roles = WjRole.defaults
        self.save
      end
    end

    # Get the automatic suggested login_name value from open id uri.
    # ex) http://a.b.c/x/y/z
    #   => z_y_x_a_b_c
    # If the suggested login name length is over 15 characters, the last segument is removed.
    # ex) http://www.example.org/path/to/login_name
    #   => login_name_to
    #    (remove the segment of 'path', 'www', 'example', and 'org')
    # This method may not returns 'valid' login_name.
    def self.get_suggest_login_name(open_id_uri)
      uri = URI.parse(open_id_uri)
      seguments = uri.path.split("/").reverse + uri.host.split(".")
      length = 0
      returns = []
      seguments.each do |seg|
        segment = seg.gsub(/[^a-z0-9_]/, '')
        if segment.length > 0
          length = length + segment.length + 1
          if length > 16
            return returns.join("_")
          else
            returns << segment
          end
        end
      end
      returns.join("_")
    end
  end
end
