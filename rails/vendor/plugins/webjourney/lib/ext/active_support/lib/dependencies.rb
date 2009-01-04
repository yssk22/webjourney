module Dependencies
  alias :rails_original_load_missing_constant :load_missing_constant
  def load_missig_constant(from_mod, const_name)
    begin
      rails_original_load_missing_constant(from_mod, const_name)
    rescue NameError => e
      # try to load component/<from_mod>/app/[controllers|models]
      puts "try #{e.message}"
      raise e
    end
  end
end
