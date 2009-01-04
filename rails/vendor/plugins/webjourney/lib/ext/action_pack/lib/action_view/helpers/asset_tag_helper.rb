module ActionView::Helpers::AssetTagHelper
  #
  # Change original rails caching(which is limited to store cache file only under /stylesheets dir)
  #
  def stylesheet_link_tag(*sources)
    options = sources.extract_options!.stringify_keys
    cache   = options.delete("cache")

    if ActionController::Base.perform_caching && cache
      joined_stylesheet_name = (cache == true ? "all" : cache) + ".css"
      joined_stylesheet_path = if joined_stylesheet_name[0] == '/'[0]
                                 File.join(RAILS_ROOT, "public", joined_stylesheet_name)
                               else
                                 File.join(STYLESHEETS_DIR, joined_stylesheet_name)
                               end
      write_asset_file_contents(joined_stylesheet_path, compute_stylesheet_paths(sources))
      stylesheet_tag(joined_stylesheet_name, options)
    else
      expand_stylesheet_sources(sources).collect { |source| stylesheet_tag(source, options) }.join("\n")
    end
  end


  #
  # make image_path to automatically resolve component images directory
  #
  alias :image_path_org :image_path
  alias :path_to_image_org :path_to_image
  def image_path(path)
    path = image_path_org(path)
    return path unless @controller.kind_of?(WebJourney::ComponentController)
    if path =~ /^\/images\//
      "/components/#{component.directory_name}#{path}"
    else
      path
    end
  end
  alias :path_to_image :image_path

end
