# == Schema Information
#
# Table name: course_modules
#
#  code       :string           not null, primary key
#  name       :string(64)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  staff_id   :bigint
#
# Indexes
#
#  index_course_modules_on_code      (code) UNIQUE
#  index_course_modules_on_staff_id  (staff_id)
#
# Foreign Keys
#
#  fk_rails_...  (staff_id => staffs.id)
#
require 'rails_helper'

RSpec.describe CourseModule, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
