# frozen_string_literal: true

FactoryBot.define do
  # ALL THE FIELDS IN THE transient BLOCK CAN BE OVERRIDDEN WITH FactoryBot.create(:standard_staff_user, .. <attribs> ..)

  factory :standard_staff_user, class: User do
    transient do
      email { 'awillis4@sheffield.ac.uk' }
      username { 'acc22aw' }
      admin { false }

      sn { 'Willis' }
      givenname { 'Adam' }
    end

    uid { 'acc22aw' }
    mail { 'awillis4@sheffield.ac.uk' }

    ou { 'COM' }
    dn { nil }
    account_type { 'student - ug' }

    after(:build) do |user, evaluator|
      FactoryBot.create(:standard_student_user, email: evaluator.email, username: evaluator.username, sn: evaluator.sn,
givenname: evaluator.givenname)

      user.email = evaluator.email
      user.mail = evaluator.email

      user.username = evaluator.username
      user.uid = evaluator.username

      user.staff = Staff.create(email: evaluator.email, admin: evaluator.admin)

      user.save
    end
  end
end
