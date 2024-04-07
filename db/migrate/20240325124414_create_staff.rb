class CreateStaff < ActiveRecord::Migration[7.0]
  def change
    create_table :staffs do |t|
      t.string :email, null: false, index: { unique: { case_sensitive: false } } # , name: 'unique_emails'
      t.timestamps
    end
  end
end
