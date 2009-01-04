# Provides partials support to test cases so they can include other partial test
# cases.
#
# The partial's commands are returned as html table rows.
module SeleniumOnRails::PartialsSupport
  include SeleniumOnRails::Paths

  # Overrides where the partial is searched for, and returns only the command table rows.
  def render_partial partial_path = default_template_name, object = nil, local_assigns = nil, status = nil
    pattern = partial_pattern partial_path
    filename = Dir[pattern].first
    raise "Partial '#{partial_path}' cannot be found! (Looking for file: '#{pattern}')" unless filename
    partial = render :file => filename, :use_full_path => false, :locals => local_assigns
    extract_commands_from_partial partial
  end

  # Extracts the commands from a partial. The partial must contain a html table
  # and the first row is ignored since it cannot contain a command.
  def extract_commands_from_partial partial
    partial = partial.match(/.*<table>.*?<tr>.*?<\/tr>(.*?)<\/table>/im)[1]
    raise "Partial '#{name}' doesn't contain any table" unless partial
    partial
  end

  private
    # Generates the file pattern from the provided partial path.
    # The starting _ and file extension don't have too be provided.
    def partial_pattern partial_path
      path = partial_path.split '/'
      filename = path.delete_at(-1)
      filename = '_' + filename unless filename.starts_with? '_'
      filename << '.*' unless filename.include? '.'
      pattern = selenium_tests_path + '/'
      pattern << path.join('/') + '/' if path
      pattern << filename
    end

end