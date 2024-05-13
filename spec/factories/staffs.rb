# frozen_string_literal: true

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
FactoryBot.define do
  # ALL THE FIELDS IN THE transient BLOCK CAN BE OVERRIDDEN WITH FactoryBot.create(:standard_staff_user, .. <attribs> ..)

  factory :standard_staff_user, class: User do
    transient do
      email { "awillis4@sheffield.ac.uk" }
      username { "acc22aw" }
      admin { false }

      sn { "Willis" }
      givenname { "Adam" }
    end

    uid { "acc22aw" }
    mail { "awillis4@sheffield.ac.uk" }

    ou { "COM" }
    dn { nil }
    account_type { "staff" }

    after(:build) do |user, evaluator|
      # implicitly create a student user to act as the concrete "backend" account
      # FactoryBot.create(:standard_student_user, email: evaluator.email, username: evaluator.username, sn: evaluator.sn, givenname: evaluator.givenname)

      user.email = evaluator.email
      user.mail = evaluator.email

      user.username = evaluator.username
      user.uid = evaluator.username

      user.staff = Staff.create(email: evaluator.email, admin: evaluator.admin)

      user.save
    end
  end
end
