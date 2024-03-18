class CreateStudent < ActiveRecord::Migration[7.0]
  def change
    #  Integer enum: home = 0, overseas = 1
    create_enum :student_fee_status, %w[home overseas]

    create_table :students do |t|
      # id primary key column is implicit
      t.string :preferred_name, null: false, limit: 24
      t.string :forename,       null: false, limit: 24
      t.string :middle_names,   default: "", limit: 64
      t.string :surname,        default: "", limit: 24

      t.string :username,       null: false, limit: 16  # seems to depend on the number of middle names
      t.string :title,          null: false, limit: 4
      t.column :fee_status,     :student_fee_status,  null: false
      t.string :ucard_number,   null: false, limit: 9

      t.string :email,          null: false, limit: 254  # technical limit of email addresses
      t.string :personal_tutor, default: "", limit: 64

      t.timestamps
    end
  end
end
