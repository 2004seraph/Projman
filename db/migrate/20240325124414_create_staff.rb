class CreateStaff < ActiveRecord::Migration[7.0]
  def change
    enable_extension 'citext'

    create_table :staffs do |t|
      t.citext :email, null: false, index: { unique: { case_sensitive: false } } # , name: 'unique_emails'

      t.boolean :admin, null: false, default: false

      t.timestamps
    end
  end
end
