# == Schema Information
#
# Table name: course_modules
#
#  id         :bigint           not null, primary key
#  name       :string(32)       not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class CourseModule < ApplicationRecord
  has_many :students
  has_many :projects
end
