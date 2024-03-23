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
FactoryBot.define do
  factory :course_module do
    
  end
end
