
module StandardHelper

  extend self

  def str_to_int(string)
    Integer(string || '')
  rescue ArgumentError
    1
  end
end