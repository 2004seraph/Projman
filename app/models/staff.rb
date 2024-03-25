# == Schema Information
#
# Table name: staffs
#
#  id         :bigint           not null, primary key
#  email      :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  unique_emails  (email) UNIQUE
#
class Staff < ApplicationRecord
  has_many :assigned_facilitators, dependent: :destroy
  has_many :modules

  validates :email, uniqueness: true, presence: true
end
