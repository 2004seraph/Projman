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
FactoryBot.define do
  factory :course_module do
    
  end
end
