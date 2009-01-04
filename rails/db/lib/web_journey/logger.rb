module WebJourney
  class CustomLogger < Logger
    def format_message(severity, timestamp, progname, msg)
      "[#{$$}][#{timestamp}][#{severity}]#{msg}\n"
    end

    # add wj_{log_level} methods to append prefix [WebJourney] (notice for application logging)
    %w(fatal error warn info debug).each do |level|
      module_eval %{
      def wj_#{level}(msg, &block)
        if block
          self.#{level} wj_msg_build('#{level}', msg) do block.call end
        else
          self.#{level} wj_msg_build('#{level}', msg)
        end
      end
    }
    end

    private
    def wj_msg_build(level, msg)
      "\e[1;34;08m[WebJourney]\e[0m - #{msg}"
    end
  end
end
