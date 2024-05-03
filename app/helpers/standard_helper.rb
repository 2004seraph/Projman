# frozen_string_literal: true

module StandardHelper
  module_function

  def str_to_int(string)
    Integer(string || '')
  rescue ArgumentError
    1
  end
end
