module ActiveRecord
  # Extension for ActiveRecord::Errors to provie more information to flexible rich client
  class Errors
    # original :
    #  <errors>
    #    <error>message</error>
    #    <error>message</error>
    #    ...
    #  </errors>
    # will be changed to : (Not implemented yet)
    #  <errors>
    #    <error>
    #      <attr>attr</attr>
    #      <message>message</message>
    #    </error>
    #    <error>
    #      <attr>attr</attr>
    #      <message>message</message>
    #    </error>
    #    ...
    #  </errors>
    #
    def to_xml(options={})
      options[:root]    ||= "errors"
      options[:indent]  ||= 2
      options[:builder] ||= Builder::XmlMarkup.new(:indent => options[:indent])

      options[:builder].instruct! unless options.delete(:skip_instruct)
      options[:builder].errors do |e|
        each_attr_message do |attr, msg|
          e.error do |detail|
            if attr.nil?
              detail.message(msg)
            else
              detail.attr(attr)
              detail.message(msg)
            end
          end
        end
      end
    end
    
    # {
    #   errors : [
    #     { attr
    #   ]
    # }
    # 
    #
    def to_json
      self.to_hash.to_json
    end

    def to_hash
      array = []
      each_attr_message do |attr, msg|
        if attr.nil?
          array << { :message => msg }
        else
          array << {
            :message => msg,
            :attr    => attr
          }
        end
      end
      { :errors => array }
    end

    private
    def each_attr_message
      @errors.each_key do |attr|
        @errors[attr].each do |msg|
          next if msg.nil?
          if attr == "base"
            yield nil, (@base.class.human_attribute_name(attr) + " " + msg)
          else
            yield attr, (@base.class.human_attribute_name(attr) + " " + msg)
          end
        end
      end
    end

  end
end
