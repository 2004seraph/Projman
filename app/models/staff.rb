class Staff < ApplicationRecord
  has_many :assigned_facilitators
  has_many :modules

end