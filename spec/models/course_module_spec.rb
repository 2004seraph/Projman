# == Schema Information
#
# Table name: course_modules
#
#  id         :bigint           not null, primary key
#  name       :string(32)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
require 'rails_helper'

RSpec.describe CourseModule, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
