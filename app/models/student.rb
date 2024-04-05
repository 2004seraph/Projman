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

require 'csv'
require 'student_data_helper'

class Student < ApplicationRecord
  has_many :groups, through: :groups_students
  has_and_belongs_to_many :course_modules, foreign_key: "course_module_code", association_foreign_key: "student_id", join_table: "course_modules_students"
  has_many :assigned_facilitators, dependent: :destroy

  enum :fee_status, { home: 'home', overseas: 'overseas' }

  @text_validation_regex = Regexp.new '[A-zÀ-ú\' -.]*'

  @email_validation_regex = Regexp.new '(?:[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'  # :nodoc:

  # required fields
  validates :preferred_name,  presence: true, length: { in: 2..24 },  format: { with: @text_validation_regex }
  validates :forename,        presence: true, length: { in: 2..24 },  format: { with: @text_validation_regex }
  validates :username,        presence: true, length: { in: 5..16 },  format: { with: @text_validation_regex }, uniqueness: true
  validates :title,           presence: true, length: { in: 2..4 },   format: { with: @text_validation_regex }
  validates :ucard_number,    presence: true, length: { is: 9 },      numericality: { only_integer: true },     uniqueness: true
  validates :email,           presence: true, length: { in: 8..254 },format: { with: @email_validation_regex }, uniqueness: true # 16 = @sheffield.ac.uk
  validates :fee_status,      presence: true

  validates :middle_names,    length: { maximum: 64 },  format: { with: @text_validation_regex }
  validates :surname,         length: { maximum: 24 },  format: { with: @text_validation_regex }
  validates :personal_tutor,  length: { maximum: 64 },  format: { with: @text_validation_regex }

  # custom validation for presence on at least one module

  def enroll_module(module_code)
    # puts module_code
    CourseModule.find(module_code).students << self
  end

  # A static method to insert a classlist into the database
  def self.bootstrap_class_list(csv)
    csv = CSV.parse(csv, headers: true)

    headers = StudentDataHelper.csv_headers

    csv.each { |csv_row|
      # put it in a hash of database_header => value
      # call Student.new with hash
      new_student_hash = {}

      csv_row.each_with_index { |_, index|
        header_database_name = csv_header_to_field headers[index]
        if column_names.include? header_database_name
          new_student_hash.store(
            header_database_name.to_sym,
            translate_csv_value(header_database_name.to_sym, csv_row[headers[index]])
          )
        end
      }

      new_student = create new_student_hash
      if new_student.valid? and new_student.persisted?
        # puts StudentDataHelper::MODULE_CODE_CSV_COLUMN
        # puts csv_row[StudentDataHelper::MODULE_CODE_CSV_COLUMN]
        # puts csv_row
        new_student.enroll_module(csv_row[StudentDataHelper::MODULE_CODE_CSV_COLUMN])
      else
        puts new_student.errors.objects.first.full_message
      end
    }
  end

  # A static method to insert a single student into the database
  def self.bootstrap_student(csv)
  end

  private

  # a static method to convert CSV header names to the correct database field name
  def self.csv_header_to_field(header_name_string)
    explicit_header_mappings = StudentDataHelper::EXPLICIT_CSV_TO_FIELD_LINK

    header_name = nil
    if explicit_header_mappings.key?(header_name_string.to_sym)
      header_name = explicit_header_mappings[header_name_string.to_sym]
    else
      header_name = header_name_string.parameterize.underscore
    end
    header_name
  end


  def self.translate_csv_value(field_symbol, value_string)
    if StudentDataHelper::CSV_VALUE_TRANSLATIONS.key?(field_symbol)
      return StudentDataHelper::CSV_VALUE_TRANSLATIONS[field_symbol].call(value_string)
    end
    value_string
  end
end
