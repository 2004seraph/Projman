# == Schema Information
#
# Table name: staffs
#
<<<<<<< HEAD
#  id                     :bigint           not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_staffs_on_email                 (email) UNIQUE
#  index_staffs_on_reset_password_token  (reset_password_token) UNIQUE
=======
#  id                  :bigint           not null, primary key
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
>>>>>>> 3747a175941b6e84bb6d41dc5e04d10846804f8a
#
class Staff < ApplicationRecord
  # Include default devise modules. Others available are:
  
  devise :trackable
  has_many :assigned_facilitators, dependent: :destroy
  has_many :modules

  validates :email, presence: true, uniqueness: { case_sensitive: false }

  # def password_required?
  #   false
  # end
end
