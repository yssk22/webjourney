module DateTimeHelper
  def t(time)
    if time
      time.strftime("%Y/%m/%d %H:%M")
    else
      "--/--/-- --:--"
    end
  end

  def d(date)
    if time
      time.strftime("%Y/%m/%d")
    else
      "--/--/--"
    end
  end
end
