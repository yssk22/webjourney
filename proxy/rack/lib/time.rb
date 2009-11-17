class Time
  # JavaScript's new Date(string) date parsing capabilities, unlike rfc3339.
  def to_json
    self.utc.strftime("%Y/%m/%d %H:%M:%S +0000").to_json
  end
end
