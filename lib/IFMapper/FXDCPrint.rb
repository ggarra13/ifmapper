
class FXDCPrint
  alias :old_font= :font=
  alias :old_font  :font

  def font
    return @f
  end

  def font=(x)
    old_font=(x)
    @f = x
  end

end
