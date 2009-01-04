module WebJourney
  module Widgets
    # The ActionView helper modules defines the methods that are available in the widget.
    module WidgetHelper
      # Generate pagination links for widget.
      def pagination_widget_links(paginator, options={}, html_options={})
        name = options[:name] || :page
        params = (options[:params] || {})
        pagination_links_each(paginator, options) do |n|
          params[name] = n
          link_widget_to(n.to_s, params, html_options)
        end
      end

      # Generate a textarea for FCKEditor
      def fckeditor_tag(name, content=nil, options={}, configs = {})
        options_default = {
          "BasePath"                 => "/javascripts/fckeditor/",
          "Width"                    => "100%",
          "Height"                   => "300"
        }.update(options)

        configs_default = {
          "CustomConfigurationsPath" => "/javascripts/webjourney/fckconfig.js",
          "StylesXmlPath"            => "/javascripts/webjourney/fckstyles.xml"
        }.update(configs)

        instance = name

        script = []
        script << "var #{instance} = new FCKeditor('#{name}');"
        # options append
        options_default.each do |k,v|
          script << "#{instance}.#{k} = #{v.to_json};"
        end
        # configs append
        configs_default.each do |k, v|
          script << "#{instance}.Config['#{k}'] = #{v.to_json};"
        end
        script << "#{instance}.ReplaceTextarea();"
        text_area_tag = text_area_tag(name, content)
        text_area_tag + javascript_tag(script.join("\n"))
      end

      # Generate a textarea for FCKEditor for the specified object
      def fckeditor(obj, method, options ={ }, configs={ })
        options_default = {
          "BasePath"                 => "/javascripts/fckeditor/",
          "Width"                    => "100%",
          "Height"                   => "300"
        }.update(options)

        configs_default = {
          "CustomConfigurationsPath" => "/javascripts/webjourney/fckconfig.js",
          "StylesXmlPath"            => "/javascripts/webjourney/fckstyles.xml"
        }.update(configs)

        instance = "#{obj}_#{method}"

        script = []
        script << "var #{instance} = new FCKeditor('#{obj}[#{method}]');"
        # options append
        options_default.each do |k,v|
          script << "#{instance}.#{k} = #{v.to_json};"
        end
        # configs append
        configs_default.each do |k, v|
          script << "#{instance}.Config['#{k}'] = #{v.to_json};"
        end
        script << "#{instance}.ReplaceTextarea();"
        text_area_tag = text_area(obj, method)
        text_area_tag + javascript_tag(script.join("\n"))
      end

      # easy to create ajax request form in the widget.
      #
      # example)
      #   form_widget_tag :action => "register"
      #
      def form_widget_tag(url_for_options = {}, xhr_options = {}, options = {}, &block)
        if url_for_options.is_a?(Hash)
          # append default option
          url_for_options[:controller] ||= params[:controller]
          url_for_options[:action] ||= params[:action]
        end

        xhr_options = {
          :method => "post",
          :evalScripts => true
        }.update(xhr_options)

        submit = []
        submit << "$A(this.elements).each(function(e){if( e.type == 'submit' ){e.disabled=true}})"
        submit << "var xhr_options = #{xhr_options.to_json}"
        submit << "xhr_options.parameters = Form.serialize(this)"
        submit << js_object.js_obj + ".xhrUpdate(#{url_for_options.to_json}, xhr_options)"
        submit << "return false"

        options[:onSubmit] =
          (options[:onSubmit] ? options[:onSubmit] + ";" : "") + submit.join(";")
        form_tag(url_for_options, options, &block)
      end
      alias :widget_form_tag :form_widget_tag

      # Creates a submit button as FormTagHelper#submit_tag before which a loading icon is placed.
      # When the button clicked, loader icon appears and the button disabled.
      def submit_widget_tag(value="Save changes", options={})
        options[:disable_with] ||= value
        onclick = []
        onclick << "this.previousSibling.style.visibility = 'visible'"
        onclick << "this.value='#{options[:disable_with]}'"
        onclick << options[:onclick] if options[:onclick]
        onclick << "return true;"
        options[:onclick] = onclick.join(";")
        icon_html = labeled_icon('ajax-loader', "loading", :tag => "img", :html_options => {:style => "visibility: hidden;"})
        submit = tag(:input, { "type" => "submit", "name" => "commit", "value" => value }.update(options.stringify_keys))
        icon_html + submit
      end
      alias :widget_submit_tag :submit_widget_tag


      # This method is similar to 'link_to'
      # When the link is clicked, the widget box is redrawn by the ajax response from url(specified <tt>url_options</tt>).
      def widget_link_to(name, url_options={ }, html_options = { })
        url_opts = {
          :controller => params[:controller],
          :layout => "block",
          :action => params[:action],
          :id => params[:id]
        }.update(url_options)
        script = <<-SCRIPT
#{js_object.js_obj}.load(#{url_opts.to_json})
SCRIPT
        content_tag('a', name,
                    html_options.merge({
                                         :href => html_options[:href] || "#",
                                         :onclick => (html_options[:onclick] ? "#{html_options[:onclick]}; " : "") + "#{script}; return false;"
                                       }))
      end
      alias :link_widget_to :widget_link_to

      # render iframe to get url
      def iframe_tag(url_options ={}, html_options={})
        html_options[:id] ||= instance.dom_id('ifm')
        id = html_options[:id]
        html_options[:src] = url_for(url_options.update(:layout => "iframe"))
        html_options[:style] ||= ""
        html_options[:style] += ";border:none;margin-left:auto; margin-right:auto;"
        html_options[:frameborder] = "0" # for IE
        onload = []
        onload << "var idoc = null";
        onload << "if( this.contentDocument ){ idoc = this.contentDocument;} else{ idoc = document.frames[id].document;}"
        onload << "this.style.height = (idoc.body.scrollHeight + 10) + 'px';"
        onload << "this.style.width = (idoc.body.scrollWidth + 10) + 'px';"
        html_options[:onload] = onload.join(";")
        id = html_options[:id]
        iframe = content_tag(:iframe, "", html_options)
        iframe
      end
    end
  end
end


