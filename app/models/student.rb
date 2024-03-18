class Student < ApplicationRecord
  enum :fee_status, { home: 0, overseas: 1 }

  has_many :groups
  has_many :modules

  has_many :assigned_facilitators

end
