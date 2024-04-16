
module ViewHelper
  extend self

  def unparamaterize(str)
    str.tr("_", " ").humanize
  end

  def remove_after_indent(str)
    x = ""
    for i in 0...str.length
      if str[i] == ' '
        return x
      end
      x += str[i]
    end
    x
  end
end