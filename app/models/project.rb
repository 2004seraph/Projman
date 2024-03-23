class Project < ApplicationRecord
  has_many :groups
  belongs_to :module
end