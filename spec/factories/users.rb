# == Schema Information
#
# Table name: users
#
#  id                 :bigint           not null, primary key
#  account_type       :string
#  current_sign_in_at :datetime
#  current_sign_in_ip :string
#  dn                 :string
#  email              :citext           default(""), not null
#  givenname          :string
#  last_sign_in_at    :datetime
#  last_sign_in_ip    :string
#  mail               :string
#  ou                 :string
#  sign_in_count      :integer          default(0), not null
#  sn                 :string
#  uid                :string
#  username           :string
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_users_on_email     (email)
#  index_users_on_username  (username)
#
FactoryBot.define do
  factory :user do

  end

  factory :standard_student_user, class: User do
    email {'awillis4@sheffield.ac.uk'}
    username {'acc22aw'}
    uid {'acc22aw'}
    mail {'awillis4@sheffield.ac.uk'}
    ou {'COM'}
    dn {nil}
    sn {'Willis'}
    givenname {'Adam'}
    account_type {'student - ug'}
  end
end
