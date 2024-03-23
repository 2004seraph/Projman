# == Schema Information
#
# Table name: course_modules
#
#  code       :string           not null, primary key
#  lead_email :string           not null
#  name       :string(32)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_course_modules_on_code  (code) UNIQUE
#
require 'rails_helper'

RSpec.describe CourseModule, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
