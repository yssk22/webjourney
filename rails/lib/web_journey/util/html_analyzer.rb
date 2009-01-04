require 'hpricot'
require 'nkf'

module WebJourney
  module Util
    module HtmlAnalyzer
      def self.analyze_from_html(html)
        result = {}
        doc = Hpricot(NKF.nkf("-w", html))
        title_elem = (doc / "html head title").first
        if title_elem
          result[:title] = title_elem.inner_html
        end
        result
      end
    end
  end
end
