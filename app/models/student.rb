# == Schema Information
#
# Table name: students
#
#  id                 :bigint           not null, primary key
#  account_type       :string
#  current_sign_in_at :datetime
#  current_sign_in_ip :string
#  dn                 :string
#  email              :citext           not null
#  fee_status         :enum             not null
#  forename           :string(24)       not null
#  givenname          :string
#  last_sign_in_at    :datetime
#  last_sign_in_ip    :string
#  mail               :string
#  middle_names       :string(64)       default("")
#  ou                 :string
#  personal_tutor     :string(64)       default("")
#  preferred_name     :string(24)       not null
#  sign_in_count      :integer          default(0), not null
#  sn                 :string
#  surname            :string(24)       default("")
#  title              :string(4)        not null
#  ucard_number       :string(9)        not null
#  uid                :string
#  username           :citext           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_students_on_email         (email)
#  index_students_on_ucard_number  (ucard_number) UNIQUE
#  index_students_on_username      (username) UNIQUE
#

require 'csv'
require 'student_data_helper'

class Student < ApplicationRecord
  include EpiCas::DeviseHelper

  devise :trackable

  has_and_belongs_to_many :groups
  has_and_belongs_to_many :course_modules#, foreign_key: "course_module_code", association_foreign_key: "student_id", join_table: "course_modules_students"
  has_many :course_projects, through: :course_modules
  has_many :events#, through: :group
  has_many :event_responses#, through: :events
  has_many :assigned_facilitators, dependent: :destroy
  has_many :milestone_responses

  enum :fee_status, { home: 'home', overseas: 'overseas' }

  @text_validation_regex = Regexp.new '[A-zÀ-ú\' -.]*'

  @email_validation_regex = Regexp.new '(?:[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&\'*+\/=?^_`{|}~-]+)*|"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])'  # :nodoc:

  # required fields
  validates :preferred_name,  presence: true, length: { in: 2..24 },  format: { with: @text_validation_regex }
  validates :forename,        presence: true, length: { in: 2..24 },  format: { with: @text_validation_regex }
  validates :middle_names,    length: { maximum: 64 },  format: { with: @text_validation_regex }
  validates :surname,         length: { maximum: 24 },  format: { with: @text_validation_regex }
  validates :username,        presence: true, length: { in: 5..16 },  format: { with: @text_validation_regex }, uniqueness: { case_sensitive: false }
  validates :title,           presence: true, length: { in: 2..4 },   format: { with: @text_validation_regex }
  validates :ucard_number,    presence: true, length: { is: 9 },      numericality: { only_integer: true },     uniqueness: true
  validates :email,           presence: true, length: { in: 8..254 },format: { with: @email_validation_regex }, uniqueness: { case_sensitive: false } # 16 = @sheffield.ac.uk
  validates :fee_status,      presence: true

  validates :personal_tutor,  length: { maximum: 64 },  format: { with: @text_validation_regex }

  def self.ldap_sync
    # def handle_name_change(name, student)
    #   if name_lookup == s.username
    #     # what the fuck
    #   elsif name_lookup != s.
    #   end
    # end

    # Student.all.each do |s|
    #   handle_name_change DatabaseHelper.get_student_first_name s, s
    #   handle_name_change DatabaseHelper.get_student_last_name s, s
    # end
  end

  def enroll_module(module_code)
    # if CourseModule.find_by(code: module_code).students.find_by(username: username) != nil
    #   return nil
    # end
    # CourseModule.find_by(code: module_code).students << self
    c = CourseModule.find_by(code: module_code)
    if c && !c.students.find_by(username: username)
      course_modules << c
      return true
    end
    false
  end

  def unenroll_module(module_code)
    c = CourseModule.find_by(code: module_code)
    if c
      c.students.delete(self)

      # remove all their facilitator positions for every project on that module
      # c.course_projects.each do |p|
      #   p.assigned_facilitators.where(student: self).delete_all
      # end

      # remove them from all groups on this module
      # groups.where(course_module: c).each do |g|
      #   g.students.delete(self)
      # end

      # puts groups.where(course_module: c)

      return true
    end
    false
  end

  # A static method to insert a classlist into the database
  def self.bootstrap_class_list(csv)
    invalid_models = []

    CSV.parse(csv, headers: true).each do |x|
      success, student = self.bootstrap_student(x)
      if not success
        invalid_models << student
      end
    end

    invalid_models
  end

  # A static method to insert a single student into the database
  def self.bootstrap_student(csv_row)
    headers = StudentDataHelper.csv_headers

    username = csv_row[StudentDataHelper::USERNAME_CSV_COLUMN]

    student =
      if Student.exists?(username: username)
        Student.find_by(username: username)
      else
        # marshal csv data into a hash of database_field_name => csv_value
        new_student_hash = {}
        csv_row.each_with_index { |_, index|
          header_database_name = csv_header_to_field headers[index]
          if column_names.include? header_database_name
            new_student_hash.store(
              header_database_name.to_sym,
              translate_csv_value(header_database_name.to_sym, csv_row[headers[index]], username)
            )
          end
        }
        create new_student_hash
      end

    if student.valid?
      student.enroll_module(csv_row[StudentDataHelper::MODULE_CODE_CSV_COLUMN])
      return true, student
    else
      return false, student
    end
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

  def self.translate_csv_value(field_symbol, value_string, username)
    if StudentDataHelper::CSV_VALUE_TRANSLATIONS.key?(field_symbol)
      return StudentDataHelper::CSV_VALUE_TRANSLATIONS[field_symbol].call(value_string, username)
    end
    value_string
  end
end
