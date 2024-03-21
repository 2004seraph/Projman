# == Schema Information
#
# Table name: students
#
#  id             :bigint           not null, primary key
#  email          :string(254)      not null
#  fee_status     :enum             not null
#  forename       :string(24)       not null
#  middle_names   :string(64)       default("")
#  personal_tutor :string(64)       default("")
#  preferred_name :string(24)       not null
#  surname        :string(24)       default("")
#  title          :string(4)        not null
#  ucard_number   :string(9)        not null
#  username       :string(16)       not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
class Student < ApplicationRecord
  has_many :groups
  has_many :modules
  has_many :assigned_facilitators

  enum :fee_status, { home: 0, overseas: 1 }

  @text_validation_regex = Regexp.new '[A-zÀ-ú\' -.]*'

  @email_validation_regex = Regexp.new '(?:[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'

  # required fields
  validates :preferred_name,  presence: true, length: { in: 2..24 },  format: { with: @text_validation_regex }
  validates :forename,        presence: true, length: { in: 2..24 },  format: { with: @text_validation_regex }
  validates :username,        presence: true, length: { in: 5..16 },  format: { with: @text_validation_regex }
  validates :title,           presence: true, length: { in: 2..4 },   format: { with: @text_validation_regex }
  validates :ucard_number,    presence: true, length: { is: 9 },      numericality: { only_integer: true }
  validates :email,           presence: true, length: { in: 16..254 },format: { with: @email_validation_regex } # 16 = @sheffield.ac.uk
  validates :fee_status,      presence: true

  validates :middle_names,    length: { maximum: 64 },  format: { with: @text_validation_regex }
  validates :surname,         length: { maximum: 24 },  format: { with: @text_validation_regex }
  validates :personal_tutor,  length: { maximum: 64 },  format: { with: @text_validation_regex }

  # A static method to insert a classlist into the database
  def self.bootstrap_class_list(csv)
    # csv = CSV.new(CSVString, **options)
    puts "hello"
  end

  # A static method to insert a single student into the database
  def self.bootstrap_student(csv)
    # csv = CSV.new(CSVString, **options)
    puts "hello"
  end
end
