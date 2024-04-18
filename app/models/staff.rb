# == Schema Information
#
# Table name: staffs
#
#  id                  :bigint           not null, primary key
#  admin               :boolean          default(FALSE), not null
#  current_sign_in_at  :datetime
#  current_sign_in_ip  :string
#  email               :citext           not null
#  last_sign_in_at     :datetime
#  last_sign_in_ip     :string
#  remember_created_at :datetime
#  sign_in_count       :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_staffs_on_email  (email) UNIQUE
#
class Staff < ApplicationRecord
  # Include default devise modules. Others available are:

  devise :trackable
  has_many :assigned_facilitators, dependent: :destroy
  has_many :modules

  validates :email, presence: true, uniqueness: { case_sensitive: false }
end
