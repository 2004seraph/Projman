class Project < ApplicationRecord
  has_many :milestones
  has_many :groups

end