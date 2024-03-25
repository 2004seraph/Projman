class Project < ApplicationRecord
  has_many :groups, dependent: :destroy
  belongs_to :module
end