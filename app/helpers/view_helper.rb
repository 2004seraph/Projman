
module ViewHelper
  extend self

  def unparamaterize(str)
    str.tr("_", " ").humanize
  end
end