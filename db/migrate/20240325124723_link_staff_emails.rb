class LinkStaffEmails < ActiveRecord::Migration[7.0]
  def change
    # add_foreign_key :course_modules, :staffs, column: :lead_email, primary_key: :email
    add_reference :course_modules, :staff, foreign_key: true
  end
end